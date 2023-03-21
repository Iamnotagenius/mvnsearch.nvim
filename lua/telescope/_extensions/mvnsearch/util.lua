local function file_exists(filepath)
    local f = io.open(filepath)
    return f ~= nil and io.close(f)
end

return { file_exists = file_exists }
