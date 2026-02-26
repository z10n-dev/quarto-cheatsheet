# quarto-cheatsheet

A Quarto extension for creating compact, multi-column cheatsheets rendered as PDF via Typst. Produces A4 landscape PDFs with a 3-column layout, styled headings, callout blocks, and auto-numbered theorem environments.

## Preview

The output is an A4 landscape PDF with:
- Hierarchical headings in blue-gradient color bands
- Up to 5 heading levels, each with a distinct shade of blue
- 3-column layout with 9pt font for density
- Callout blocks and numbered theorem environments

## Installation

```bash
quarto add noelschaller/quarto-cheatsheet
```

Or copy the `_extensions/cheatsheet/` directory into your project.

**Requirements:** Quarto >= 1.4.0

## Usage

Set the format to `cheatsheet-typst` in your document's YAML front matter:

```yaml
---
title: "My Cheatsheet"
date: today
author: "Your Name"
format: cheatsheet-typst
---
```

Then write content using standard Markdown. Sections (`##`) become column break hints — the 3-column layout flows content automatically.

```markdown
## Section Title

Regular paragraph content, lists, code blocks, etc.

## Another Section

More content here.
```

## Features

### Callout Blocks

Use raw Typst blocks for styled callouts:

````markdown
```{=typst}
#tipp[This is a tip!]
```

```{=typst}
#warnung[This is a warning!]
```
````

| Block | Appearance |
|-------|-----------|
| `#tipp[...]` | Blue left-border callout with **Tipp:** label |
| `#warnung[...]` | Red left-border callout with **⚠️ Warnung:** label |

### Theorem Environments

Use fenced divs to create numbered theorem-style blocks. Numbering resets at each top-level heading and follows the format `<section>.<number>`.

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

Available environments: `theorem`, `definition`, `corollar`, `lemma`, `proposition`

Labels rendered: `The.`, `Def.`, `Cor.`, `Lem.`, `Prop.`

## Extension Files

| File | Purpose |
|------|---------|
| `_extension.yml` | Extension metadata and default format options |
| `typst-template.typ` | Page layout, heading styles, column setup |
| `typst-show.typ` | Binds Quarto metadata (title, author, date) to the template |
| `callouts.typ` | Defines `#tipp` and `#warnung` callout blocks |
| `theorems.typ` | Defines numbered theorem environments |
| `blocks-filter.lua` | Pandoc Lua filter that converts fenced divs to Typst function calls |

## Default Format Options

| Option | Value |
|--------|-------|
| Paper | A4 |
| Orientation | Landscape |
| Columns | 3 |
| Margin | 1cm (x and y) |
| Font size | 9pt |

## License

MIT