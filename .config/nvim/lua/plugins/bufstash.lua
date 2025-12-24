return {
  {
    "carlesoctav/tasker.nvim",
    config = function()
      local bufstash = require("bufstash")
      vim.keymap.set("n", "<leader>bs", bufstash.select_stash_picker)
      vim.keymap.set("n", "<leader>bn", bufstash.add_stash_picker)
      vim.keymap.set("n", "<c-e>", bufstash.toggle_buf_list)
      vim.keymap.set("n", "<leader>bd", bufstash.delete_stash_picker)
      vim.keymap.set("n", "<leader>ba", bufstash.add_buf_curr_buf)
      vim.keymap.set("n", "<leader>bh", bufstash.hide_non_stash_buffers)
    end,
  }
}
