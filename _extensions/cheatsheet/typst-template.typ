#let cheatsheet(
  title: none,
  authors: (),
  date: none,
  cols: 3,
  doc,
) = {
  set page(
    paper: "a4",
    flipped: true,
    margin: (x: 1cm, y: 1cm),
  )
  set text(size: 9pt)
  set heading(numbering: none)

  // Titel-Bereich
  if title != none {
    block(width: 100%)[
      #text(size: 14pt, weight: "bold")[#title]
      #h(1fr)
      #text(size: 8pt, fill: gray)[#date]
    ]
    line(length: 100%)
    v(0.3cm)
  }

  // Dreispaltiges Layout
  columns(cols, gutter: 1em, doc)
}
