local lib = require("go")

require("nvim-treesitter.configs").setup {
  auto_install = not lib.is_win,
  highlight = {
    enable = true,
    disable = {"json", "yaml"}
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "+",
      node_decremental = "_",
      node_incremental = "+"
    }
  },
  indent = {
    enable = true
  },
  textobjects = {
    lsp_interop = {
      enable = true,
      peek_definition_code = {
        ["L"] = "@function.outer",
        ["M"] = "@class.outer"
      }
    },
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["ib"] = "@block.inner",
        ["ab"] = "@block.outer",
        ["iF"] = "@call.inner",
        ["aF"] = "@call.outer",
        ["iC"] = "@class.inner",
        ["aC"] = "@class.outer",
        ["ic"] = "@conditional.inner",
        ["ac"] = "@conditional.outer",
        ["if"] = "@function.inner",
        ["af"] = "@function.outer",
        ["iL"] = "@loop.inner",
        ["aL"] = "@loop.outer",
        ["ia"] = "@parameter.inner",
        ["aa"] = "@parameter.outer",
        ["is"] = "@statement.outer",
        ["as"] = "@statement.outer"
      }
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]s"] = "@statement.outer",
        ["]m"] = "@block.outer"
      },
      goto_next_end = {
        ["]S"] = "@statement.outer",
        ["]M"] = "@block.outer"
      },
      goto_previous_start = {
        ["[s"] = "@statement.outer",
        ["[m"] = "@block.outer"
      },
      goto_previous_end = {
        ["[S"] = "@statement.outer",
        ["[M"] = "@block.outer"
      }
    },
    swap = {
      enable = true,
      swap_previous = {},
      swap_next = {}
    }
  }
}

require("treesitter-context").setup {
  multiline_threshold = 1
}
