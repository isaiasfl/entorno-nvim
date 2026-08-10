local fields = {
  module = "module_css",
  centre = "centre_css",
  teacher = "teacher_css",
}

local function escape_css_string(value)
  return value
    :gsub("\\", "\\\\")
    :gsub('"', '\\"')
    :gsub("\r\n", "\\A ")
    :gsub("[\n\r\f]", "\\A ")
    :gsub("[%z\1-\8\11\14-\31\127]", function(character)
      return string.format("\\%X ", string.byte(character))
    end)
end

function Meta(metadata)
  for source, target in pairs(fields) do
    if metadata[source] then
      local value = pandoc.utils.stringify(metadata[source])
      metadata[target] = pandoc.MetaString(escape_css_string(value))
    end
  end

  return metadata
end
