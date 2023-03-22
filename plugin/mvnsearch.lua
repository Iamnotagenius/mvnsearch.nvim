local mvnsearch = require('telescope').extensions.mvnsearch.mvnsearch
vim.api.nvim_create_user_command("MvnSearch", function(context)
    mvnsearch {
        query = context.fargs[1],
    }
end, { nargs = 1 })
