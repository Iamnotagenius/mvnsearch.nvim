local telescope = require("telescope")

local config = require("telescope._extensions.mvnsearch.config")
local util = require("telescope._extensions.mvnsearch.util")
local mvnsearch_actions = require("telescope._extensions.mvnsearch.actions")
local pagers = require("telescope._extensions.mvnsearch.pagers")

local function mvnsearch(opts)
    opts = vim.tbl_extend("keep", opts, config)

    if not opts.query then
        print("Options must have 'query' key")
    end
    local packages, total = util.make_query(opts.query, opts.rows)
    local picker = util.maven_picker(opts, packages, total)
    picker:find()
    print(string.format("Got %d results. (%d pages)", total, pagers.get_from_buffer(picker.prompt_bufnr):max_page() + 1))
end

return telescope.register_extension {
    setup = function(opts)
        local default_actions = {
            default_action = mvnsearch_actions.insert_to_build_script,
            mappings = {
                n = {
                    y = mvnsearch_actions.yank,
                    n = mvnsearch_actions.next_page,
                    p = mvnsearch_actions.prev_page,
                    o = mvnsearch_actions.insert_to_build_script
                },
                i = {
                    ['<C-y>'] = mvnsearch_actions.yank,
                    ['<C-n>'] = mvnsearch_actions.next_page,
                    ['<C-p>'] = mvnsearch_actions.prev_page,
                    ['<C-o>'] = mvnsearch_actions.insert_to_build_script,
                    ['<C-s>'] = mvnsearch_actions.new_query
                }
            }
        }
        opts = vim.tbl_deep_extend("keep", opts, default_actions)
        config.setup(opts)
    end,
    exports = {
        mvnsearch = mvnsearch,
        actions = mvnsearch_actions,
        inserters = require("telescope._extensions.mvnsearch.inserters")
    }
}
