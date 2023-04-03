local M = {}

local default_opts = {
    gradle_macro = '/dependencies<CR>$%O{depstr}<Esc>==:w<CR>',
    yank_register = 'd',
    preferred_build_system = require("telescope._extensions.mvnsearch.inserters").kotlin_gradle,
    default_action = {},
    mappings = {},
    rows = 30,
    xml_declaration = {
        version = "1.0",
        encoding = "UTF-8"
    }
}

M.setup = function(opts)
    for key, value in pairs(default_opts) do
        M[key] = value
    end
    for key, value in pairs(opts) do
        M[key] = value
    end
end

return M
