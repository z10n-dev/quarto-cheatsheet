#let callout(body, title, color) = block(
  width: 100%,
  fill: color.lighten(95%),
  radius: 6pt,
  above: 10pt,
  below: 10pt
)[
  #block(
    width: 100%,
    fill: color.darken(10%),
    inset: 8pt,
    radius: (top-left: 4pt, top-right: 4pt),
    below: 0pt,
  )[#text(fill: white, weight: "bold")[#title]]
  #block(
    width: 100%,
    fill: color.lighten(90%),
    inset: 8pt,
    radius: (bottom-left: 4pt, bottom-right: 4pt),
    above: 0pt,
  )[#body]
]


#let tipp(suffix: "", body) = callout(body, [*Tipp:* #suffix], blue)
#let warnung(suffix: "", body) = callout(body, [*⚠️ Warnung:* #suffix], red)