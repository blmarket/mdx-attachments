local builtin = require('telescope.builtin')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local uuid = require('uuid-nvim')

local M = { initialized = false }

function M.create_save_path(ext)
    local id = uuid.get_v4({ quotes = "none" })

    return "./uploads/" .. id .. ext
end

function M.find_import_location(bufnr)
    -- In current buffer, find first line after front matters.
    local parser = vim.treesitter.get_parser(bufnr)
    local tree = parser:parse()[1]

    local query = vim.treesitter.query.parse('markdown', '(minus_metadata) @a')

    for _, match, _ in query:iter_matches(tree:root(), bufnr) do
        local tmp = match[1]:end_()
        return tmp
    end
    return 0
end

function M.pick_media()
    local bufnr = vim.api.nvim_get_current_buf()
    local line_num = M.find_import_location(bufnr)
    local src_dir = "/home/blmarket/Pictures"

    builtin.find_files({
        prompt_title = "< Pick your media file to add >",
        cwd = src_dir,
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local filepath = src_dir .. "/" .. selection[1]
                -- extract extension from selection
                local extension = filepath:match("^.+(%..+)$")
                local save_path = M.create_save_path(extension)
                vim.fn.system{"cp",filepath,save_path}
                vim.api.nvim_buf_set_lines(bufnr, line_num, line_num, false, {'import image from "' .. save_path .. '"'})
            end)
            return true
        end
    })
end

function M.setup()
    if M.initialized then
        return
    end
    -- Initialization code for the plugin
    vim.api.nvim_create_user_command('PickFile', M.pick_media, {})
    M.initialized = true
end

return M
