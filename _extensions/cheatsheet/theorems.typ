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
      breakable: true
    )[
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
