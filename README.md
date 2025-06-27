# 🧠 ollamarun.nvim

**Chat with local LLMs (like DeepSeek Coder) directly inside Neovim** using an interactive markdown buffer and the [Ollama](https://ollama.com) CLI.

The Chat is inside a markdown file, which makes it easier to beautify the code snippets as well as formatting with the help of plugins like **markdownpreview** and **marksman**.

> Perfect for in-editor AI coding assistants, explanations, or note-taking with models like `deepseek-coder-v2`, `llama3`, `codellama`, etc.

---

## ✨ Features

- Interactive chat with Ollama inside a `markdown` buffer
- Lightweight, no external dependencies
- Auto-updates the buffer with streamed responses
- Cleaned output (strips ANSI escape codes)
- Simple `<CR>` based interaction

---

## 📦 Installation

### `lazy.nvim`

```lua
{
  "Dheeraj-Murthy/ollamarun.nvim",
  config = function()
    require("ollamarun").setup({
      model = "deepseek-coder-v2" -- optional, defaults to this
    })
  end
}
```

### `packer.nvim`

```lua
use {
  "Dheeraj-Murthy/ollamarun.nvim",
  config = function()
    require("ollamarun").setup()
  end
}
```

---

## 🚀 Usage

1. Run `:OllamarunChat` to open or jump to the chat buffer (`OllamaChat.md`)
2. Type your message in the last line of the buffer
3. Press `<Enter>` in normal mode to send it to the model
4. Response will stream back inline

---

## 🧠 Requirements

- [Ollama](https://ollama.com) installed (`ollama run ...` must work in your terminal)
- Any Ollama-compatible model (e.g. `deepseek-coder-v2`, `codellama`, `llama3`, etc.)

To get started with a model:

```bash
ollama run deepseek-coder-v2
```

---

## 🖼️ Preview

![OllamaChat output](media/chat_screenshot.jpg)

▶️ [Click to watch the demo](media/demo-fast.mp4)

_Coming soon: GIF showing chat in action._

---

## 🛠️ TODO / Roadmap

- [ ] Add prompt history / persistence
- [ ] Add model switching from inside Neovim
- [ ] Telescope integration to browse old sessions
- [ ] Markdown formatting for roles (🤖, 🙋‍♂️)

---

## 👤 Author

**M. S. Dheeraj Murthy**  
[GitHub](https://github.com/Dheeraj-Murthy) · [LinkedIn](https://www.linkedin.com/in/dheeraj-murthy-m-s-6b7784290)

---

## 💬 Contribution

PRs, ideas, and issues are all welcome!

## If you build something cool on top of this (e.g., prompt templates, command chaining, or Telescope plugins), please open an issue or PR and share!
