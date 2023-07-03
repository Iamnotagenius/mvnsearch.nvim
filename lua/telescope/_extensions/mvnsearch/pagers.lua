local M = {}

local Pager = {}

function Pager:get_start()
    return self.page * self.rows
end

function Pager:next()
    if self.page == self:max_page() then
        self.page = 0
        return
    end
    self.page = self.page + 1
end

function Pager:prev()
    if self.page == 0 then
        self.page = self:max_page()
        return
    end
    self.page = self.page - 1
end

function Pager:max_page()
    return math.ceil(self.total / self.rows) - 1
end

function Pager:__index(key)
    if getmetatable(self)[key] then
        return getmetatable(self)[key]
    end
    return vim.b[self.prompt_bufnr].pager[key]
end

function Pager:__newindex(key, value)
    local buffer_pager = vim.b[self.prompt_bufnr].pager
    buffer_pager[key] = value
    vim.b[self.prompt_bufnr].pager = buffer_pager
end

function M.new(query, rows, total, prompt_bufnr)
    vim.b[prompt_bufnr].pager = {
        query = query,
        rows = rows,
        page = 0,
        total = total,
        chosen = {}
    }
    local pager = {
        prompt_bufnr = prompt_bufnr
    }
    setmetatable(pager, Pager)
    return pager
end

function M.get_from_buffer(prompt_bufnr)
    local pager = { prompt_bufnr = prompt_bufnr }
    setmetatable(pager, Pager)
    return pager
end

return M
