#let tipp(body) = block(
  width: 100%,
  fill: blue.lighten(85%),
  inset: 6pt,
  radius: 3pt,
  stroke: (left: 3pt + blue)
)[*💡 Tipp:* #body]

#let warnung(body) = block(
  width: 100%,
  fill: red.lighten(85%),
  inset: 6pt,
  radius: 3pt,
  stroke: (left: 3pt + red)
)[*⚠️ Warnung:* #body]

#let definition(title: none, body) = block(
  width: 100%,
  fill: green.lighten(85%),
  inset: 6pt,
  radius: 3pt,
  stroke: (left: 3pt + green)
)[
  #if title != none [*#title* \ ]
  #body
]
