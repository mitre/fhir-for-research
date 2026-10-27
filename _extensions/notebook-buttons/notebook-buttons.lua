local function stringify(value)
  if value == nil then
    return nil
  end

  return pandoc.utils.stringify(value)
end

local function option(kwargs, name, default)
  local value = stringify(kwargs[name])
  if value == nil or value == "" then
    return default
  end

  return value
end

local function enabled(kwargs, name)
  return option(kwargs, name, "true"):lower() ~= "false"
end

local function escape_html(value)
  return value
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
end

local function badge(href, image, alt, download)
  local download_attribute = download and " download" or ""

  return string.format(
    '<a href="%s"%s><img src="%s" alt="%s"></a>',
    escape_html(href),
    download_attribute,
    escape_html(image),
    escape_html(alt)
  )
end

return {
  ["notebook-buttons"] = function(args, kwargs)
    local notebook = option(kwargs, "notebook", stringify(args[1]))
    if notebook == nil or notebook == "" then
      error("notebook-buttons requires a notebook filename")
    end

    local repository = option(kwargs, "repository", os.getenv("COLLAB_BINDER_PATH"))
    if repository == nil or repository == "" then
      error("notebook-buttons requires repository=... or COLLAB_BINDER_PATH")
    end

    local github_path = option(kwargs, "github-path", notebook)
    local binder_path = option(kwargs, "binder-path", github_path)
    local download_path = option(kwargs, "download-path", "./" .. notebook)
    local github_ref = option(kwargs, "github-ref", os.getenv("COLLAB_BINDER_REF") or "main")
    local binder_ref = option(kwargs, "binder-ref", github_ref)
    local buttons = {}

    if enabled(kwargs, "colab") then
      table.insert(buttons, badge(
        "https://colab.research.google.com/github/" .. repository .. "/blob/" .. github_ref .. "/" .. github_path,
        "https://colab.research.google.com/assets/colab-badge.svg",
        "Open in Colab"
      ))
    end

    if enabled(kwargs, "nbviewer") then
      table.insert(buttons, badge(
        "https://nbviewer.jupyter.org/github/" .. repository .. "/blob/" .. github_ref .. "/" .. github_path,
        "https://raw.githubusercontent.com/jupyter/design/refs/heads/main/logos/Badges/nbviewer_badge.svg",
        "View in NBViewer"
      ))
    end

    if enabled(kwargs, "download") then
      table.insert(buttons, badge(
        download_path,
        "https://img.shields.io/badge/download-notebook-F37626?logo=jupyter",
        "Download notebook",
        true
      ))
    end

    if enabled(kwargs, "binder") then
      table.insert(buttons, badge(
        "https://mybinder.org/v2/gh/" .. repository .. "/" .. binder_ref .. "?urlpath=%2Fdoc%2Ftree%2F" .. binder_path,
        "https://mybinder.org/badge_logo.svg",
        "Launch Binder"
      ))
    end

    return pandoc.RawInline("html", table.concat(buttons, " "))
  end
}
