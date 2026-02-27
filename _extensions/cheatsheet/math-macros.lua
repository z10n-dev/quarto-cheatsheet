local math_macros = {
  ["\\NN"] = "\\mathbb{N}",
  ["\\ZZ"] = "\\mathbb{Z}",
  ["\\QQ"] = "\\mathbb{Q}",
  ["\\RR"] = "\\mathbb{R}",
  ["\\CC"] = "\\mathbb{C}",
}

local function apply_math_macros(text)
  for latex_cmd, typst_equiv in pairs(math_macros) do
    text = text:gsub(latex_cmd, typst_equiv)
  end
  return text
end

return apply_math_macros