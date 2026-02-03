local lib = require("go")

require("nvim-treesitter").setup {}

local filetypes = {}
for parser, _ in pairs(require("nvim-treesitter.parsers")) do
  for _, ft in pairs(vim.treesitter.language.get_filetypes(parser)) do
    table.insert(filetypes, ft)
  end
end

vim.api.nvim_create_autocmd(
  "FileType",
  {
    group = lib.group,
    pattern = filetypes,
    callback = function()
      vim.treesitter.start()
    end
  }
)

require("treesitter-context").setup {
  enable = true,
  multiline_threshold = 1
}

require("nvim-treesitter-textobjects").setup {
  select = {
    lookahead = true
  }
}

local selector = require("nvim-treesitter-textobjects.select")
for lhs, rhs in pairs {
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
} do
  vim.keymap.set(
    {"x", "o"},
    lhs,
    function()
      selector.select_textobject(rhs, "textobjects")
    end
  )
end

local mover = require("nvim-treesitter-textobjects.move")
for lhs, rhs in pairs {
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
} do
  for l, r in pairs(rhs) do
    vim.keymap.set(
      {"n", "x", "o"},
      l,
      function()
        mover[lhs](r, "textobjects")
      end
    )
  end
end

-- lsp_interop = {
--   peek_definition_code = {
--     ["L"] = "@function.outer",
--     ["M"] = "@class.outer"
--   }
-- },
