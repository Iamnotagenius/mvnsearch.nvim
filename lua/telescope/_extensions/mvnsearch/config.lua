local M = {}

local default_opts = {
    gradle_macro = '/dependencies<CR>$%O{depstr}<Esc>==:w<CR>',
    yank_register = 'd',
    preferred_build_system = require("telescope._extensions.mvnsearch.inserters").kotlin_gradle,
    default_action = {},
    mappings = {}
}

M.setup = function(opts)
    for key, default_value in pairs(default_opts) do
        M[key] = opts[key] or M[key] or default_value
    end
end

return M
