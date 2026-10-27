# Notebook buttons shortcode

Use `notebook-buttons` to render the standard Colab, NBViewer, download, and
Binder badges for a workshop notebook:

```markdown
{{< notebook-buttons notebook="01-fhir-analysis.ipynb" github-path="workshops/data-analysis-cds/01-fhir-analysis.ipynb" binder=false >}}
```

The shortcode reads the default GitHub repository and branch from
`COLLAB_BINDER_PATH` and `COLLAB_BINDER_REF`. Override them with
`repository="owner/repository"`, `github-ref`, or `binder-ref` when needed.

Each button is enabled by default. Disable individual buttons with
`colab=false`, `nbviewer=false`, `download=false`, or `binder=false`.

Binder is disabled on the Data Analysis/CDS pages because the generated
notebook branch does not contain a Binder environment specification.

Use `download-path` when the generated notebook is not located next to the
rendered page.
