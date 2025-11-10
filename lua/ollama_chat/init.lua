local M = {}

local chat_bufnr = nil
local response_buffer = ""
local response_line = nil

-- Clean terminal escape sequences from ollama output
local function clean_output(str)
    return str
        :gsub('\27%[[0-9;]*[a-zA-Z]', '')
        :gsub('\r', '')
        :gsub('\x1b%]133;.-\a', '')
end

-- Look for existing buffer
local function get_chat_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf)
            and vim.api.nvim_buf_get_name(buf):match("OllamaChat%.md$")
        then
            return buf
        end
    end
    return nil
end

-- Parse chat buffer into a list of messages
-- Each block starts with ### User / ### Assistant
local function parse_chat(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local messages, role, content = {}, nil, {}

    local function flush()
        if role and #content > 0 then
            table.insert(messages, {
                role = role,
                content = table.concat(content, "\n")
            })
        end
    end

    for _, line in ipairs(lines) do
        if line:match("^### User") then
            flush()
            role, content = "user", {}
        elseif line:match("^### Assistant") then
            flush()
            role, content = "assistant", {}
        elseif line:match("^### System") then
            flush()
            role, content = "system", {}
        else
            if role then table.insert(content, line) end
        end
    end
    flush()
    return messages
end

-- Convert messages into plain text for ollama run
local function format_messages(messages)
    local parts = {}
    for _, m in ipairs(messages) do
        table.insert(parts, string.format("%s:\n%s", m.role, m.content))
    end
    return table.concat(parts, "\n\n")
end

-- Insert a fresh ### User block and move cursor there
local function insert_user_block(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
        "",
        "### User",
        ""
    })
    local line = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function setup_keymap(bufnr, model)
    if vim.b[bufnr].ollama_chat_mapped then return end

    vim.keymap.set("n", "<CR>", function()
        local messages = parse_chat(bufnr)
        if #messages == 0 or messages[#messages].role ~= "user" then
            vim.notify("Please add a ### User block with content", vim.log.levels.WARN)
            return
        end

        -- Add Assistant block
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
            "",
            "### Assistant",
            "🤖 Thinking..."
        })
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
            on_exit = function()
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(bufnr) then
                        insert_user_block(bufnr)
                    end
                end)
            end,
        })

        local input_text = format_messages(messages)
        vim.fn.chansend(job_id, input_text .. "\n")
        vim.fn.chanclose(job_id, "stdin")
    end, { buffer = bufnr, noremap = true, silent = true })

    vim.b[bufnr].ollama_chat_mapped = true
end

function M.setup(opts)
    opts = opts or {}
    local model = opts.model or "deepseek-coder-v2"

    vim.api.nvim_create_user_command("OllamaChat", function()
        chat_bufnr = get_chat_buf()

        if not chat_bufnr then
            chat_bufnr = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_set_name(chat_bufnr, "OllamaChat.md")
            vim.api.nvim_buf_set_option(chat_bufnr, "filetype", "markdown")
            vim.api.nvim_buf_set_option(chat_bufnr, "wrap", true)
            vim.api.nvim_buf_set_option(chat_bufnr, "linebreak", true)

            -- starter system message
            vim.api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, {
                "### System",
                "You are a helpful coding assistant inside Neovim.",
                "",
            })

            insert_user_block(chat_bufnr)
        end

        vim.api.nvim_set_current_buf(chat_bufnr)
        setup_keymap(chat_bufnr, model)
    end, {})
end

return M
