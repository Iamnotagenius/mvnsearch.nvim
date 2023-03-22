local telescope = require("telescope")

local config = require("telescope._extensions.mvnsearch.config")
local util = require("telescope._extensions.mvnsearch.util")
local mvnsearch_actions = require("telescope._extensions.mvnsearch.actions")

local function mvnsearch(opts)
    opts = vim.tbl_extend("keep", opts, config)

    if not opts.query then
        print("Options must have 'query' key")
    end
    util.maven_picker(opts, util.new_pager(opts.query, opts.rows)):find()
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
