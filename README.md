# quarto-cheatsheet

A Quarto extension for compact, multi-column cheatsheets rendered to PDF with
Typst. It produces A4 landscape pages with a three-column layout, colored
section headings, callout blocks, auto-numbered theorem environments, and
short math macros.

## Features

- A4 landscape pages with a configurable number of columns
- Five heading levels, each with its own shade of blue
- Compact 9pt body text by default
- Styled Markdown tables with blue headers, subtle striped rows, and compact spacing
- Callouts: tip, warning, and neutral blocks
- Numbered theorem-style environments
- Math macros for common number sets (`\NN`, `\ZZ`, `\QQ`, `\RR`, `\CC`, `\LL`)
- Markdown content throughout, including formatted text inside callouts and
  theorem blocks

## Requirements

- Quarto >= 1.4.0
- Typst support in your Quarto installation

## Create a Cheatsheet from the Template

The recommended way to start a new cheatsheet is with the Quarto starter
template:

```bash
quarto use template z10n-dev/quarto-cheatsheet
```

Quarto copies the template and its extension into the target directory. The
starter document is `index.qmd`. Move into the new directory and render it:

```bash
cd my-cheatsheet
quarto render
```

You can also render a specific document:

```bash
quarto render index.qmd
```

### Project Setup

`quarto use template` does not copy hidden files, so the template ships a
visible `template/` folder plus a `setup.sh` script. Run it once in the new
project to create `.gitignore`, `.envrc`, and a CI workflow:

```bash
./setup.sh            # interactive platform choice
./setup.sh github     # github | gitlab | gitea | none
```

It creates:

- `.gitignore`
- `.envrc` (direnv + the project flake)
- a render workflow for the chosen platform:
  - GitHub: `.github/workflows/render.yml`
  - GitLab: `.gitlab-ci.yml`
  - Gitea: `.gitea/workflows/render.yml`

Each workflow renders `index.qmd` through the project's Nix flake and names the
PDF after the repository, for example `my-cheatsheet.pdf`. GitHub and GitLab
upload it as a CI artifact. Gitea publishes it as a release attachment instead,
so the PDF can be downloaded directly without a ZIP archive. Its download link
is printed in the job log and added to the job summary when supported.

For Gitea, configure an Actions repository secret named `GITEA_TOKEN` containing
a personal access token with repository write access (`write:repository`). Each
run creates a release tagged `build-<run number>`.

The `template/` folder stores the source dotfiles and workflows.

## Use in an Existing Project

From the root of an existing Quarto project, add only the format extension:

```bash
quarto add z10n-dev/quarto-cheatsheet
```

This installs the extension under `_extensions/cheatsheet/` without replacing
your project files. Set the format in the YAML front matter of any document
that should use the cheatsheet layout:

```yaml
---
title: "My Cheatsheet"
date: today
author: "Your Name"
format: cheatsheet-typst
cols: 3
font-size: 9pt
---
```

Then render the document normally:

```bash
quarto render path/to/cheatsheet.qmd
```

## Update an Existing Project

### Full Template Update

Run the update script from your existing cheatsheet project directory:

```bash
./update.sh          # detects an installed workflow, otherwise asks
./update.sh gitea    # github | gitlab | gitea | none
```

The script downloads the current template from GitHub and asks before replacing:

- `_extensions/cheatsheet/` (layout, styles, and filters)
- `flake.nix` and `flake.lock` (including Chromium for Mermaid)
- `template/`, `setup.sh`, and `update.sh`
- the selected CI workflow

Existing versions are saved under `.cheatsheet-backups/<timestamp>.<suffix>/`.
Custom QMD documents, `_quarto.yml`, and existing `.envrc` content are left
unchanged. Existing `.gitignore` rules are kept; only an ignore entry for the
backup directory is appended if needed. Missing dotfiles are created.

Review the changes afterward and reapply any custom extension, flake, or workflow
changes from the backup. The new `flake.lock` also updates the pinned development
dependencies. Then reload direnv (or enter `nix develop`) and render the document.
With `none`, existing CI workflows are left unchanged.

For non-interactive updates or a particular upstream branch/tag:

```bash
./update.sh gitea --yes
./update.sh gitea --ref main
```

Older projects may not have `update.sh` yet. Download it once, inspect it, then run:

```bash
curl -fL https://raw.githubusercontent.com/z10n-dev/quarto-cheatsheet/main/update.sh -o update.sh
chmod +x update.sh
./update.sh gitea
```

The script requires Bash and Git. `CHEATSHEET_REPOSITORY` can point to a different
template Git repository, such as a fork.

### Extension Only

To update only the extension without changing the flake or workflows:

```bash
quarto update extension z10n-dev/quarto-cheatsheet
```

Quarto shows the installed and available versions and asks for confirmation.
To inspect installed extensions first, run:

```bash
quarto list extensions
```

The update replaces only `_extensions/cheatsheet/`. It does not overwrite your
documents or reapply changes from the starter `index.qmd`, because a starter
template is copied only when the project is created. Commit local changes
before updating if you have modified files inside `_extensions/cheatsheet/`.

## Usage

Write content using standard Markdown. Content flows automatically across the
columns; use headings to structure the sheet.

```markdown
# Section Title

Regular paragraph content, lists, code blocks, tables, etc.

## Subsection

More content here.
```

The document title, author, and date are rendered as a compact header inside
the first column.

### Configuration

| Option      | Default | Description          |
|-------------|---------|----------------------|
| `cols`      | `3`     | Number of columns    |
| `font-size` | `9pt`   | Body font size       |

The `title`, `author`, and `date` fields from the front matter are rendered in
the header. Paper size, orientation, margins, heading styles, and column gutters
are defined by the extension.

### Tables

Standard Markdown tables automatically use a light blue header with bold text,
subtle alternating row backgrounds, and a thin blue header separator instead of
a full grid. Column alignment, inline formatting, and math are preserved:

```markdown
| Set       | Symbol | Dimension |
|:----------|:------:|----------:|
| **Real**  | $\RR$  |         1 |
| Complex   | $\CC$  |         2 |
```

### Mermaid Diagrams

Use a Mermaid code block to include a diagram:

````markdown
```{mermaid}
flowchart LR
  A[Markdown] --> B[Quarto] --> C[PDF]
```
````

For a smaller diagram, set `width` directly inside the Mermaid block:

````markdown
```{mermaid}
%%| width: "70%"
flowchart LR
  A[Markdown] --> B[Quarto] --> C[PDF]
```
````

The percentage limits the diagram to that fraction of the available column (or
callout) width. Values greater than 0% and up to 100% are supported, including
decimals. Captions and labels can be used alongside this option. Use `width`, not
`fig-width`, for percentages: Quarto interprets `fig-width` as inches.

Images, including Mermaid diagrams, automatically shrink to fit the available
column width while preserving their aspect ratio. This also respects the inset
inside callouts. Small images are not enlarged; explicit figure sizes are capped
at the available width. For long diagrams, `flowchart TD` often keeps labels more
readable than a wide `flowchart LR`.

Quarto needs Chrome or Chromium to render Mermaid. The project's Nix flake
provides Chromium via `QUARTO_CHROMIUM`; outside Nix, run
`quarto install chrome-headless-shell` if no supported browser is installed.

### Callouts

Callouts can be written as fenced divs. The body supports normal Markdown
formatting, and `title` is optional:

```markdown
::: tipp
This is a tip.
:::

::: {.warnung title="Careful"}
This is a warning with a custom title.
:::

::: default
A neutral callout.
:::
```

| Class       | Appearance                                      |
|-------------|-------------------------------------------------|
| `tipp`      | Blue callout with a **Tipp:** heading           |
| `warnung`   | Red callout with a **⚠️ Warnung:** heading      |
| `default`   | Gray callout with a custom heading              |

The same blocks are available directly in raw Typst:

````markdown
```{=typst}
#tipp(title: "Optional title", [This is a tip.])
#warnung([This is a warning.])
```
````

### Theorem Environments

Fenced divs create numbered theorem-style blocks. Numbering resets at each
level-1 heading and is displayed as `<section>.<number>`. The body supports
Markdown formatting, and `title` is optional:

```markdown
::: theorem
A theorem statement.
:::

::: {.theorem title="Named Theorem"}
A theorem with a title.
:::

::: definition
A definition.
:::
```

| Class         | Label  |
|---------------|--------|
| `theorem`     | `The.` |
| `definition`  | `Def.` |
| `corollar`    | `Cor.` |
| `lemma`       | `Lem.` |
| `proposition` | `Prop.`|

### Math Macros

The following LaTeX-style macros are rewritten automatically in inline and
display math:

| Macro | Renders as   |
|-------|--------------|
| `\NN` | $\mathbb{N}$ |
| `\ZZ` | $\mathbb{Z}$ |
| `\QQ` | $\mathbb{Q}$ |
| `\RR` | $\mathbb{R}$ |
| `\CC` | $\mathbb{C}$ |
| `\LL` | $\mathbb{L}$ |

Example:

```markdown
The natural numbers are $\NN = \{1, 2, 3, \dots\}$.
```

## Extension Files

| File               | Purpose                                                      |
|--------------------|--------------------------------------------------------------|
| `_extension.yml`   | Extension metadata and default format options                |
| `typst-template.typ` | Page layout, heading styles, and column setup              |
| `typst-show.typ`   | Binds Quarto metadata (title, author, date, options) to the template |
| `callouts.typ`     | Defines `#tipp`, `#warnung`, and `#default` callout blocks    |
| `theorems.typ`     | Defines numbered theorem environments                         |
| `blocks-filter.lua` | Converts fenced divs to Typst calls and applies math macros  |
| `math-macros.lua`  | Defines the math macro substitutions                          |
| `setup.sh`         | Creates dotfiles and the CI workflow after `quarto use template` |
| `update.sh`        | Updates an existing project, with backups of replaced files    |
| `template/`        | Source dotfiles and CI workflows for `setup.sh`               |

## Development

The repository includes a Nix flake with Quarto, Pandoc, Python, R, and Chromium, plus a
minimal `_quarto.yml` so the example in the subdirectory can resolve the
extension. With Nix and direnv installed:

```bash
direnv allow
quarto render
```

Without direnv, use `nix develop` instead. `quarto render` builds both
`index.qmd` and the full feature showcase in `examples/example.qmd`.

Run the offline tests with:

```bash
python3 -B -m unittest discover -s tests -v
```

Image layout tests use Quarto's bundled Typst compiler and are skipped if Quarto
is not installed. They cover one to four columns, nested blocks, callouts, and
inline images without requiring a browser.

## License

MIT
