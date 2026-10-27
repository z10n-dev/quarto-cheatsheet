-- This filter converts fenced divs with specific classes to Typst function calls and applies math macros to inline and display math.
local apply_math_macros = require("math-macros")

function Math(el)
  local text = apply_math_macros(el.text)
  return pandoc.Math(el.mathtype, text)
end

-- List of block types that should be converted
local block_types = {
  "theorem",
  "definition",
  "corollar",
  "lemma",
  "proposition",
  "tipp",
  "warnung",
  "default"
}

-- Create a map for quick lookup  
local supported_blocks = {}
for _, block_type in ipairs(block_types) do
  supported_blocks[block_type] = true
end

-- Quarto retains Mermaid cell options on the surrounding .cell div.
-- Its renderer consumes fig-width as inches, so use width for percentages.
local function mermaid_width(div)
  local width = div.attributes["width"]
  if not width or not div.classes:includes("cell") then
    return nil
  end

  local has_mermaid = false
  div:walk({
    Image = function(image)
      if image.src:match("mermaid%-figure%-%d+%.") then
        has_mermaid = true
      end
    end
  })
  if not has_mermaid then
    return nil
  end

  local percentage = tostring(width):match("^%s*(%d*%.?%d+)%s*%%%s*$")
  local value = tonumber(percentage)
  if not value or value <= 0 or value > 100 then
    error('Mermaid width must be a percentage greater than 0% and at most 100% (for example: width: "70%").')
  end
  return percentage .. "%"
end

-- Convert fenced divs to typst function calls
function Div(div)
  local width = mermaid_width(div)
  if width then
    div.content:insert(1, pandoc.RawBlock("typst", "#block(width: " .. width .. ")["))
    div.content:insert(pandoc.RawBlock("typst", "]"))
    return div
  end

  local func_name = nil
  
  -- Check if it has a supported block type class
  for i, class in ipairs(div.classes) do
    if supported_blocks[class] then
      func_name = class
      break
    end
  end
  
  if func_name then
    -- Get title from attribute if provided
    local title = div.attributes["title"] or ""
    
    -- Convert content to Typst, preserving formatting
    local content = pandoc.write(pandoc.Pandoc(div.content), "typst")
    
    -- Build the function call
    local typst_code
    if title ~= "" then
      typst_code = "#" .. func_name .. "(title: \"" .. title .. "\")[\n  " .. content .. "\n]"
    else
      typst_code = "#" .. func_name .. "()[\n  " .. content .. "\n]"
    end
    
    return pandoc.RawBlock("typst", typst_code)
  end
end
