#let cheatsheet(
  title: "Test",
  author: "Max Mustermann",
  date: none,
  cols: 4,
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

  // Dreispaltiges Layout mit Titel
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
  #doc
  ])
  
}
