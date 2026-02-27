-- Math macro replacements for Typst
local math_macros = {
  ["\\NN"] = "\\mathbb{N}",
  ["\\ZZ"] = "\\mathbb{Z}",
  ["\\QQ"] = "\\mathbb{Q}",
  ["\\RR"] = "\\mathbb{R}",
  ["\\CC"] = "\\mathbb{C}",
}

-- Replace math macros in Math elements
function Math(el)
  local text = el.text
  for latex_cmd, typst_equiv in pairs(math_macros) do
    text = text:gsub(latex_cmd, typst_equiv)
  end
  return pandoc.Math(el.mathtype, text)
end