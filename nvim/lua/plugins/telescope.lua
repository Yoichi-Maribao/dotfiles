local image_exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true, ico = true, svg = true }

local function is_image(filepath)
  local ext = (filepath:match "%.(%w+)$" or ""):lower()
  return image_exts[ext]
end

---@type LazySpec
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "3rd/image.nvim" },
    opts = function(_, opts)
      local default_maker = require("telescope.previewers").buffer_previewer_maker

      opts.defaults = opts.defaults or {}
      opts.defaults.buffer_previewer_maker = function(filepath, bufnr, maker_opts)
        if is_image(filepath) then
          -- image.nvim rendering must run in main loop
          vim.schedule(function()
            local ok, image = pcall(require, "image")
            if not ok then return end

            local winid = maker_opts and maker_opts.winid
            if not winid or not vim.api.nvim_win_is_valid(winid) then return end

            -- clear all previous images on this window
            local prev_images = image.get_images { window = winid }
            for _, prev in ipairs(prev_images) do
              prev:clear()
            end

            local win_width = vim.api.nvim_win_get_width(winid)
            local win_height = vim.api.nvim_win_get_height(winid)

            local img = image.from_file(filepath, {
              window = winid,
              buffer = bufnr,
              width = math.floor(win_width * 0.9),
              height = math.floor(win_height * 0.9),
              x = 1,
              y = 1,
              with_virtual_padding = true,
            })

            if img then img:render() end
          end)
        else
          -- clear any previous image before showing text preview
          vim.schedule(function()
            local ok, image = pcall(require, "image")
            if ok then
              local winid = maker_opts and maker_opts.winid
              if winid and vim.api.nvim_win_is_valid(winid) then
                local prev_images = image.get_images { window = winid }
                for _, prev in ipairs(prev_images) do
                  prev:clear()
                end
              end
            end
          end)
          default_maker(filepath, bufnr, maker_opts)
        end
      end
    end,
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          ["<Leader>fW"] = {
            function()
              require("telescope.builtin").live_grep {
                additional_args = { "--hidden", "--no-ignore" },
              }
            end,
            desc = "Find words in all files",
          },
          ["<Leader>fT"] = {
            function()
              vim.ui.input({ prompt = "Glob pattern (e.g. *.scss): " }, function(pattern)
                if pattern and pattern ~= "" then
                  require("telescope.builtin").live_grep { glob_pattern = pattern }
                end
              end)
            end,
            desc = "Find words by file type",
          },
        },
      },
    },
  },
}
