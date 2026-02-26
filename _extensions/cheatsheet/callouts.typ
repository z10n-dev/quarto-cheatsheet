#let tipp(body) = block(
  width: 100%,
  fill: blue.lighten(85%),
  inset: 5pt,
  radius: 2pt,
  stroke: (left: 3pt + blue),
  above: 5pt,
  below: 4pt
)[*Tipp:* #body]

#let warnung(body) = block(
  width: 100%,
  fill: red.lighten(85%),
  inset: 5pt,
  radius: 2pt,
  stroke: (left: 3pt + red)
)[*⚠️ Warnung:* #body]