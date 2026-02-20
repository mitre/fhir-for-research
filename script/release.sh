#!/bin/bash
set -euo pipefail

# =============================================================================
# Release Script
# =============================================================================
# GOAL:
# Create squashed releases from the 'dev' branch onto 'main', where 'main'
# contains only clean, squashed release commits suitable for public consumption.
#
# CONTEXT:
# - 'dev' branch contains the full development history
# - 'main' branch has a different history due to squashing (commits on main
#   don't exist in dev's history)
# - Some files/folders in dev are internal-only and must be stripped from releases
# - Releases are merged via GitHub PRs and must fast-forward onto main
#
# IMPLEMENTATION:
# 1. Determine release number using date-based versioning (yyyy-mm-dd, with
#    .a, .b, .c suffixes for multiple same-day releases)
# 2. Find the base commit by looking for the last release tag on dev (tags mark
#    which dev commits have been released, since main's squashed commits don't
#    appear in dev's history)
# 3. Collect all commit messages since the last release for the squash commit
# 4. Create a release branch from main, squash-merge dev onto it
# 5. Strip internal-only paths from the staged changes
# 6. Commit with release number as title and bulleted list of included commits
# 7. Tag the current dev HEAD to mark what's included in this release
#
# USAGE:
#   ./script/release.sh
#   # Resolve conflicts if any, then:
#   git push -u origin release/yyyy-mm-dd
#   # Create PR on GitHub, merge with fast-forward
#
#
# AI CITATION: This file includes content generated with the assistance of
# Claude Opus 4.6, a generative AI tool. Claude Opus 4.6 was used to generate
# and modify the source code accompanying documentation using solely public
# information. All AI-generated content has been reviewed/edited by the MITRE
# team to ensure accuracy and followed MITRE's generative AI use guidelines.
#
# =============================================================================

# release.sh - Create a release branch from dev to merge into main

# Find the remote for MITRE GitLab
GITLAB_URL="git@gitlab.mitre.org:fhir-for-research/web.git"
while read -r name url direction; do
  if [[ "$direction" == "(fetch)" ]]; then
    if [[ "$url" == "$GITLAB_URL" ]]; then
      GITLAB_REMOTE="$name"
    fi
  fi
done < <(git remote -v)

if [[ -z "$GITLAB_REMOTE" ]]; then
  echo "Error: No git remote found with URL '$GITLAB_URL'."
  echo "Add it, e.g.: git remote add gitlab $GITLAB_URL"
  exit 1
fi

echo "Using GitLab remote: $GITLAB_REMOTE ($GITLAB_URL)"

# Specify branch names
MAIN_BRANCH="main"
DEV_BRANCH="dev"

# Author alias pairs to exclude if canonical is present (format: "canonical|alias")
EXCLUDE_AUTHOR_ALIASES=(
    "Max Masnick <max@masnick.org>|Max Masnick Ph.D. <mmasnick@mitre.org>"
)

# Files and folders to strip from releases (relative to repo root), loaded from file
STRIP_PATHS_FILE="script/strip-paths.txt"
STRIP_PATHS=()
if [[ -f "$STRIP_PATHS_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        STRIP_PATHS+=("$line")
    done < "$STRIP_PATHS_FILE"
else
    echo "Warning: $STRIP_PATHS_FILE not found; no paths will be stripped." >&2
fi

# Ensure we're up to date
git fetch ${GITLAB_REMOTE}

# Determine release number (date-based: yyyy-mm-dd, with .a-.z suffix if needed)
TODAY=$(date +%Y-%m-%d)
EXISTING=$(git tag -l "release/${TODAY}*" | sort | tail -n1)

if [[ -z "$EXISTING" ]]; then
    RELEASE_NUM="$TODAY"
elif [[ "$EXISTING" == "$TODAY" ]]; then
    RELEASE_NUM="${TODAY}.a"
else
    # Extract suffix letter and increment
    SUFFIX=$(echo "$EXISTING" | sed "s/release\/${TODAY}\.//")
    if [[ "$SUFFIX" == "z" ]]; then
        echo "Error: Cannot create more than 27 releases in a single day." >&2
        exit 1
    fi
    # Increment letter: a→b, b→c, ..., y→z
    NEXT_SUFFIX=$(echo "$SUFFIX" | tr 'a-y' 'b-z')
    RELEASE_NUM="${TODAY}.${NEXT_SUFFIX}"
fi

echo "Creating release: $RELEASE_NUM"

RELEASE_BRANCH="release/${RELEASE_NUM}"

# Find the base: last release tag on main, or merge-base as fallback
LAST_TAG=$(git describe --tags --abbrev=0 "${GITLAB_REMOTE}/${DEV_BRANCH}" 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
    BASE_COMMIT="$LAST_TAG"
else
    BASE_COMMIT=$(git merge-base "${GITLAB_REMOTE}/${MAIN_BRANCH}" "${GITLAB_REMOTE}/${DEV_BRANCH}")
fi

if [[ -z "$BASE_COMMIT" ]]; then
    echo "Error: No common ancestor found between ${MAIN_BRANCH} and ${DEV_BRANCH}." >&2
    echo "This may indicate the branches share no history." >&2
    exit 1
fi

if [[ $(git rev-parse "${GITLAB_REMOTE}/${DEV_BRANCH}") == $(git rev-parse "$BASE_COMMIT") ]]; then
    echo "Error: ${DEV_BRANCH} has no commits beyond ${MAIN_BRANCH}." >&2
    exit 1
fi

echo "Base commit: $BASE_COMMIT"

# Collect commit messages from dev since base
COMMIT_MESSAGES=$(git log --oneline --first-parent "${BASE_COMMIT}..${GITLAB_REMOTE}/${DEV_BRANCH}" | awk '{$1=""; print "- " substr($0,2)}')

if [[ -z "$COMMIT_MESSAGES" ]]; then
    echo "No new commits on dev since last release."
    exit 1
fi

# Collect unique commit authors and build Co-authored-by trailers
AUTHOR_EMAIL=$(git config user.email || echo "")
AUTHOR_NAME=$(git config user.name || echo "")
AUTHORS=$(git log --format='%an <%ae>' --first-parent "${BASE_COMMIT}..${GITLAB_REMOTE}/${DEV_BRANCH}" | sort -u || true)
# Exclude current commit author by email, if set
if [[ -n "$AUTHOR_EMAIL" ]]; then
    AUTHORS=$(printf "%s\n" "$AUTHORS" | grep -vi " <$AUTHOR_EMAIL>$" || true)
fi
# Exclude known alias identities when their canonical identity is present
CURRENT_ID=""
if [[ -n "$AUTHOR_NAME" && -n "$AUTHOR_EMAIL" ]]; then
    CURRENT_ID="$AUTHOR_NAME <$AUTHOR_EMAIL>"
fi
for pair in "${EXCLUDE_AUTHOR_ALIASES[@]}"; do
    IFS='|' read -r CANONICAL ALIAS <<< "$pair"
    if [[ -n "$CANONICAL" && -n "$ALIAS" ]]; then
        if printf "%s\n" "$AUTHORS" | grep -Fqx "$CANONICAL" || { [[ -n "$CURRENT_ID" ]] && [[ "$CURRENT_ID" == "$CANONICAL" ]]; }; then
            AUTHORS=$(printf "%s\n" "$AUTHORS" | grep -Fvx "$ALIAS" || true)
        fi
    fi
done
COAUTHORS=$(printf "%s\n" "$AUTHORS" | awk 'NF { print "Co-authored-by: " $0 }' || true)

# Create release branch from main
if git show-ref --verify --quiet "refs/heads/$RELEASE_BRANCH"; then
    echo "Local branch '$RELEASE_BRANCH' already exists."
    if [ -t 0 ]; then
        read -r -p "Delete the local branch and recreate? [y/N]: " REPLY || true
    else
        echo "Non-interactive session detected; cannot prompt to delete the local branch."
        echo "Aborting. Please delete the local branch manually or choose a different release number."
        exit 1
    fi
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        git branch -D "$RELEASE_BRANCH"
    else
        echo "Aborting. Please delete the local branch or choose a different release number."
        exit 1
    fi
fi
git checkout -b "$RELEASE_BRANCH" "${GITLAB_REMOTE}/${MAIN_BRANCH}"

# Squash merge dev onto the release branch
if ! git merge --squash "${GITLAB_REMOTE}/${DEV_BRANCH}"; then
    echo ""
    echo "=== Merge conflicts detected ==="
    echo "Resolve conflicts, then run:"
    echo "  git rm -rf ${STRIP_PATHS[*]}"
    echo "  git add -A"
    echo "  git commit -F .git/RELEASE_MSG"
    echo "  git push -u ${GITLAB_REMOTE} ${RELEASE_BRANCH}"
    echo ""
    printf "%s\n\n%s\n\n%s\n" "$RELEASE_NUM" "$COMMIT_MESSAGES" "$COAUTHORS" > .git/RELEASE_MSG
    exit 0
fi

# Remove stripped paths from the staged changes
for path in "${STRIP_PATHS[@]}"; do
    if git ls-files --stage | grep -q "	${path%/}"; then
        git reset HEAD -- "$path" 2>/dev/null || true
        git checkout HEAD -- "$path" 2>/dev/null || rm -rf "$path"
    elif [[ -e "$path" ]]; then
        git reset HEAD -- "$path" 2>/dev/null || true
        rm -rf "$path"
    fi
done

# Prepare release commit message
MSG_FILE=".git/RELEASE_MSG"
printf "%s\n\n%s\n\n%s\n" "$RELEASE_NUM" "$COMMIT_MESSAGES" "$COAUTHORS" > "$MSG_FILE"
trap 'rm -f "$MSG_FILE"' EXIT # Clean up the $MSG_FILE after the script exits

# Offer to edit commit message if interactive
if [ -t 0 ]; then
    read -r -p "Edit the release commit message before committing? [y/N]: " REPLY || true
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        EDITOR_CMD="${VISUAL:-${EDITOR:-vi}}"
        echo "Opening commit message in: $EDITOR_CMD $MSG_FILE"
        "$EDITOR_CMD" "$MSG_FILE" || { echo "Editor exited with error. Aborting commit."; exit 1; }
    fi
fi

# Commit with release message
git commit -F "$MSG_FILE"

# Tag and push release (interactive)
TAG_CMD=(git tag "release/$RELEASE_NUM" "${GITLAB_REMOTE}/${DEV_BRANCH}")
PUSH_TAG_CMD=(git push "$GITLAB_REMOTE" refs/tags/release/"$RELEASE_NUM")
PUSH_BRANCH_CMD=(git push -u "$GITLAB_REMOTE" refs/heads/"${RELEASE_BRANCH}")

if [ -t 0 ]; then
    read -r -p "Run tag and push commands automatically now? [y/N]: " REPLY || true
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Running commands:"
        echo "${TAG_CMD[@]}"
        "${TAG_CMD[@]}"
        echo "${PUSH_TAG_CMD[@]}"
        "${PUSH_TAG_CMD[@]}"
        echo "${PUSH_BRANCH_CMD[@]}"
        "${PUSH_BRANCH_CMD[@]}"
    else
        echo "To tag and push manually, run:"
        echo "${TAG_CMD[@]}"
        echo "${PUSH_TAG_CMD[@]}"
        echo "${PUSH_BRANCH_CMD[@]}"
    fi
else
    echo "Non-interactive session; run the following to tag and push:"
    echo "${TAG_CMD[@]}"
    echo "${PUSH_TAG_CMD[@]}"
    echo "${PUSH_BRANCH_CMD[@]}"
fi
