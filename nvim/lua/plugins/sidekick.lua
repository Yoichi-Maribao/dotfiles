-- Store active sidekick terminal instance globally
_G.sidekick_active_terminal = nil
-- Store last prompt for recall
_G.sidekick_last_prompt = nil

return {
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        win = {
          keys = {
            stopinsert = { "<esc><esc>", "stopinsert", mode = "t" },
            hide_n = { "q", "hide", mode = "n" },
            prompt = { "<c-p>", "prompt" },
            insert_from_buffer = {
              "<c-n>",
              function(t)
                _G.sidekick_active_terminal = t

                local bufnr = vim.fn.bufnr "sidekick://prompt"
                if bufnr ~= -1 then
                  local winid = vim.fn.bufwinid(bufnr)
                  if winid ~= -1 then
                    vim.api.nvim_set_current_win(winid)
                  else
                    vim.cmd ":drop sidekick://prompt"
                  end
                else
                  vim.cmd ":10new sidekick://prompt"
                end
              end,
              mode = { "n", "t" },
            },
          },
        },
        mux = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-.>",
        function() require("sidekick.cli").focus() end,
        desc = "Sidekick Focus",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle { focus = true } end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function() require("sidekick.cli").close() end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function() require("sidekick.cli").send { msg = "{this}" } end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function() require("sidekick.cli").send { msg = "{file}" } end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          -- Get visual selection text directly to avoid treesitter context error
          vim.cmd 'normal! "vy'
          local text = vim.fn.getreg "v"
          require("sidekick.cli").send { msg = text }
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<leader>ac",
        function() require("sidekick.cli").toggle { name = "claude", focus = true } end,
        desc = "Sidekick Toggle Claude",
      },
    },
    config = function(_, opts)
      require("sidekick").setup(opts)

      -- sidekick://prompt 用の一時バッファ設定
      vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
        pattern = { "sidekick://prompt" },
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()

          vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
          vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
          vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })

          -- q / Ctrl-n でバッファを閉じる, Q で強制閉じ
          vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>q<CR>", { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-n>", "<Cmd>q<CR>", { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, "n", "Q", "<Cmd>q!<CR>", { noremap = true, silent = true })

          -- Ctrl-l で前回のプロンプトを復元
          vim.keymap.set({ "n", "i" }, "<c-l>", function()
            if _G.sidekick_last_prompt then
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, _G.sidekick_last_prompt)
              vim.notify("Last prompt restored", vim.log.levels.INFO)
            else
              vim.notify("No saved prompt", vim.log.levels.WARN)
            end
          end, { buffer = bufnr, noremap = true, silent = true })

          -- 挿入モードで開始
          vim.schedule(function() vim.cmd "startinsert" end)

          -- Enter でプロンプトを送信
          vim.keymap.set("n", "<CR>", function()
            local sidekick_t = _G.sidekick_active_terminal
            if not sidekick_t then
              vim.notify("No active Sidekick instance found", vim.log.levels.ERROR)
              return
            end

            local current_win = vim.api.nvim_get_current_win()
            local prompt = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            _G.sidekick_last_prompt = prompt

            sidekick_t:send(table.concat(prompt, "\n"))

            if sidekick_t:is_open() then sidekick_t:focus() end

            vim.defer_fn(function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
              vim.defer_fn(function()
                vim.api.nvim_set_current_win(current_win)
                vim.cmd "bw!"
              end, 100)
            end, 100)
          end, { noremap = true, silent = true, buffer = bufnr })
        end,
      })
    end,
  },
  -- Copilot LSP enabled via after/lsp/copilot.lua
  {
    "AstroNvim/astrolsp",
    optional = true,
    opts = {
      servers = { "copilot" },
    },
  },
}
