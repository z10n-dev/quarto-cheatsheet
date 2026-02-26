#let tipp(body) = block(
  width: 100%,
  fill: blue.lighten(85%),
  inset: 5pt,
  radius: 2pt,
  stroke: (left: 3pt + blue)
)[*Tipp:* #body]

#let warnung(body) = block(
  width: 100%,
  fill: red.lighten(85%),
  inset: 5pt,
  radius: 2pt,
  stroke: (left: 3pt + red)
)[*⚠️ Warnung:* #body]