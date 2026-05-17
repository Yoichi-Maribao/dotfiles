---@type LazySpec
return {
  "3rd/image.nvim",
  ft = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "ico", "svg" },
  opts = {
    backend = "kitty",
    -- ImageMagick CLI (flake.nix の imagemagick) を使う。luarocks/magick 不要。
    processor = "magick_cli",
    max_width = 100,
    max_height = 30,
    max_height_window_percentage = 60,
    max_width_window_percentage = 80,
    editor_only_render_when_focused = true,
  },
}
