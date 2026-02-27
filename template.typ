// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#let cheatsheet(
  title: "Test",
  author: "Max Mustermann",
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

#set page(
  paper: "us-letter",
  margin: (x: 1cm,y: 1cm,),
  numbering: "1",
)

// Verbindet Quarto-Metadaten mit dem Template
#show: cheatsheet.with(
  title: [Mein Cheatsheet],
  date: [2026-02-26],
  author: [Max Mustermann],
)
$\newcommand{\NN}{\mathbb{N}}$
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
#let theorem_counter = counter("theorem")

// Reset the theorem counter every time a level 1 heading appears
#show heading.where(level: 1): it => {
  it
  theorem_counter.update(1)
}

// Helper function to reduce duplication
#let create_numbered_block(label, title: none, body) = {
    context {
        let section_num = counter(heading).at(here()).first()
        theorem_counter.step()
        let block_num = theorem_counter.at(here()).first()
        let display_num = [#section_num.#block_num]

        block(
            width: 100%,
            breakable: true,
            inset: 0pt,
            above: 5pt,
            below: 4pt
        )[
            #set par(leading: 0.5em)
            #text(weight: "bold")[#label #display_num #if title != none [(#title)]:] 
            #body
        ]
    }
}

#let theorem(title: none, body) = {
  create_numbered_block("The.", title: title, body)
}

#let definition(title: none, body) = {
  create_numbered_block("Def.", title: title, body)
}

#let corollar(title: none, body) = {
  create_numbered_block("Cor.", title: title, body)
}

#let lemma(title: none, body) = {
  create_numbered_block("Lem.", title: title, body)
}

#let proposition(title: none, body) = {
  create_numbered_block("Prop.", title: title, body)
}

= Abschnitt
<abschnitt>
Inhalt der ersten Spalte… Lorem Ipsum dolore sit amet, consectetur adipiscing elit. Donec a diam lectus. Sed sit amet ipsum mauris. Maecenas congue ligula ac quam viverra nec consectetur ante hendrerit. Donec et mollis dolor. Praesent et diam eget libero egestas mattis sit amet vitae augue. Nam tincidunt congue enim, ut porta lorem lacinia consectetur.

#tipp(suffix: "Test", [Das ist ein Tipp!])
= Abschnitt
<abschnitt-1>
Inhalt der zweiten Spalte…

#theorem()[
  Eine wichtige Definition. #emph[Test]

]
#theorem(title: "My Theorem", [Eine wichtige Definition. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec a diam lectus. Sed sit *amet* ipsum mauris. Maecenas congue ligula ac quam viverra nec consectetur ante hendrerit. Donec et mollis dolor. Praesent et diam eget libero egestas mattis sit amet vitae augue. Nam tincidunt congue enim, ut porta lorem lacinia consectetur.])
#theorem()[
  Eine wichtige Definition.

]
#theorem(title: "My Theorem")[
  Eine wichtige Definition. Lorem ipsum dolor sit amet, consectetur
adipiscing elit. Donec a diam lectus. Sed sit amet ipsum mauris.
Maecenas congue ligula ac quam viverra nec consectetur ante hendrerit.
Donec et mollis dolor. Praesent et diam eget libero egestas mattis sit
amet vitae augue. Nam tincidunt congue enim, ut porta lorem lacinia
consectetur.

]
#definition()[
  Die Menge der #strong[natürlichen Zahlen] ist definiert als
$bb(N) = { 1 \, 2 \, 3 \, dots.h }$. Zählt man die Null noch dazu,
schreibt man
\$\\mathbb{N}\_0 = \\NN\\cup \\{0\\} = \\{0,1,2,3,\\dots\\}\$

]




