// Verbindet Quarto-Metadaten mit dem Template
#show: cheatsheet.with(
$if(title)$
  title: [$title$],
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(author)$
  author: [$author$],
$endif$
$if(cols)$
  cols: $cols$,
$endif$
$if(font-size)$
  font-size: $font-size$,
$endif$
)
