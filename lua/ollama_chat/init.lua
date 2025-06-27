local M = {}

local chat_bufnr = nil
local response_buffer = ""
local response_line = nil

local function clean_output(str)
    return str
        :gsub('\27%[[0-9;]*[a-zA-Z]', '')
        :gsub('\r', '')
        :gsub('\x1b%]133;.-', '')
end

local function get_chat_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match("OllamaChat%.md$") then
            return buf
        end
    end
    return nil
end

local function setup_keymap(bufnr, model)
    if vim.b[bufnr].ollamarun_mapped then return end

    vim.keymap.set("n", "<CR>", function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local last_line = lines[#lines]

        if not last_line or last_line == "" then
            vim.notify("No input to send", vim.log.levels.WARN)
            return
        end

        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "🤖 Thinking..." })
        response_buffer = ""
        response_line = vim.api.nvim_buf_line_count(bufnr) - 1

        local cmd = { "ollama", "run", model }
        if vim.fn.executable(cmd[1]) == 0 then
            vim.notify("Ollama is not installed or not in PATH", vim.log.levels.ERROR)
            return
        end

        local job_id = vim.fn.jobstart(cmd, {
            stdout_buffered = false,
            stderr_buffered = false,
            stdin = "pipe",
            stderr = "stdout",
            on_stdout = function(_, data)
                if not data then return end
                response_buffer = response_buffer .. table.concat(data, '\n')

                vim.schedule(function()
                    if not response_line or not vim.api.nvim_buf_is_valid(bufnr) then return end

                    local cleaned = clean_output(response_buffer)
                    local lines = vim.split(cleaned, '\n', { trimempty = false })
                    local line_count = vim.api.nvim_buf_line_count(bufnr)

                    vim.api.nvim_buf_set_lines(bufnr, response_line, line_count, false, lines)
                end)
            end,
        })

        vim.fn.chansend(job_id, last_line .. "\n")
        vim.fn.chanclose(job_id, "stdin")
    end, { buffer = bufnr, noremap = true, silent = true })

    vim.b[bufnr].ollamarun_mapped = true
end

function M.setup(opts)
    opts = opts or {}
    local model = opts.model or "deepseek-coder-v2"

    vim.api.nvim_create_user_command("OllamarunChat", function()
        chat_bufnr = get_chat_buf()

        if not chat_bufnr then
            chat_bufnr = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_set_name(chat_bufnr, "OllamaChat.md")
            vim.api.nvim_buf_set_option(chat_bufnr, 'filetype', 'markdown')
            vim.api.nvim_buf_set_option(chat_bufnr, 'wrap', true)
            vim.api.nvim_buf_set_option(chat_bufnr, 'linebreak', true)
        end

        vim.api.nvim_set_current_buf(chat_bufnr)
        setup_keymap(chat_bufnr, model)
    end, {})
end

return M
