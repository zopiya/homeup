local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require("telescope.actions")

telescope.setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    mappings = {
      i = {
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-u>"] = false,  -- 允许 Ctrl+U 清空输入框
      },
    },
  },
  pickers = {
    find_files = { hidden = true },  -- 显示隐藏文件
  },
})

-- 加载 fzf 原生扩展（需要 telescope-fzf-native 已安装）
pcall(telescope.load_extension, "fzf")
