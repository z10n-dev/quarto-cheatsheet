#let cheatsheet(
  title: "Test",
  author: "Max Mustermann",
  date: none,
  cols: 3,
  font-size: 9pt,
  doc,
) = {
  set page(
    paper: "a4",
    flipped: true,
    margin: (x: 1cm, y: 1cm),
  )
  set text(size: font-size)
  set heading(numbering: "1")

  // Compact Markdown tables, matching the blue heading palette.
  set table(
    stroke: none,
    inset: (x: 5pt, y: 3pt),
    fill: (_, y) => if y == 0 {
      rgb("#dbeafe")
    } else if calc.even(y) {
      rgb("#f1f5f9")
    },
  )
  // Pandoc inserts an explicit rule beneath Markdown table headers.
  set table.hline(stroke: 0.5pt + rgb("#93c5fd"))
  show table.cell.where(y: 0): set text(
    fill: rgb("#0d2b6b"),
    weight: "bold",
  )
  
  // Headings
  set heading(numbering: "1.1")
  let heading-colors = (
    rgb("#0d2b6b"),  // level 1 - darkest
    rgb("#1a56a8"),  // level 2
    rgb("#2878d6"),  // level 3
    rgb("#5ba3f5"),  // level 4
    rgb("#93c5fd"),  // level 5 - lightest
  )
  show heading: it => {
    let color = heading-colors.at(it.level - 1, default: blue)
    block(
      fill: color,
      inset: 4pt,           // Space between text and edge of the blue box
      radius: 3pt,          // Rounded corners
      width: 100%,          // Make it fill the entire column width
      above: 5pt,
      below: 5pt,
      {
        set text(fill: white, weight: "bold")
        it
      }
    )
  }

  // Multi-column layout with document header
  columns(cols, gutter: 1em, [
  #grid(
    columns: 1fr,
    row-gutter: 5pt, // This controls the "line height" between elements
    align: center,
    text(size: 14pt, weight: "bold")[#title],
    text(size: 10pt, weight: "medium")[#author],
    text(size: 8pt, fill: gray)[#date]
)
  #set par(leading: 0.5em)
  // Surround lists with the same gap as a normal line, not a new paragraph.
  #show list: set block(above: 0.5em, below: 0.5em)
  #show enum: set block(above: 0.5em, below: 0.5em)
  #doc
  ])
  
}
