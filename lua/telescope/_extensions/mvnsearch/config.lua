local actions = require("telescope._extensions.mvnsearch.actions")

local M = {}

local default_opts = {
    gradle_macro = '/dependencies<CR>$%O{depstr}<Esc>==:w<CR>',
    yank_register = 'd',
    preferred_build_system = require("telescope._extensions.mvnsearch.inserters").kotlin_gradle,
    action = actions.insert_to_build_script,
    mappings = {
        n = {
            y = actions.yank,
            i = actions.insert_to_build_script
        },
        i = {
            ["<M-i>"] = actions.insert_to_build_script,
        }
    }
}

M.setup = function(opts)
    M.opts = default_opts
    for key, value in pairs(opts) do
        M.opts[key] = value
    end
end

return M
