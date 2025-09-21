local lib = require("go")

vim.opt.tagfunc = "v:lua.vim.lsp.tagfunc"
vim.opt.formatexpr = "v:lua.vim.lsp.formatexpr()"

vim.api.nvim_create_autocmd(
  {"BufEnter", "CursorHold", "InsertLeave"},
  {
    pattern = "<buffer>",
    callback = function()
      vim.lsp.codelens.refresh()
    end
  }
)

vim.api.nvim_create_autocmd(
  {"CursorHold", "CursorHoldI"},
  {
    pattern = "<buffer>",
    callback = function()
      vim.lsp.buf.document_highlight()
    end
  }
)

vim.api.nvim_create_autocmd(
  {"CursorMoved"},
  {
    pattern = "<buffer>",
    callback = function()
      vim.lsp.buf.clear_references()
    end
  }
)

for _, mode in pairs {"n", "v"} do
  vim.keymap.set(
    mode,
    "H",
    function()
      vim.diagnostic.open_float()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gw",
    function()
      vim.lsp.buf.code_action()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gp",
    function()
      vim.lsp.buf.definition()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    "gP",
    function()
      vim.lsp.buf.references()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    [[<leader>j]],
    function()
      vim.diagnostic.setloclist()
    end,
    {noremap = true}
  )

  vim.keymap.set(
    mode,
    [[<leader>J]],
    function()
      vim.lsp.buf.setqflist()
    end,
    {noremap = true}
  )
end

(function()
  local loadpath = vim.fs.joinpath(vim.fn.stdpath("config"), "apriori", "lsp.json")
  local json = lib.read_json(loadpath)

  if coq ~= nil then
    cfg = coq.lsp_ensure_capabilities(cfg)
  end
  if chad ~= nil then
    cfg = chad.lsp_ensure_capabilities(cfg)
  end

  for name, conf in pairs(json) do
    local overrides = {
      cmd = conf.args and vim.iter({{conf.bin}, conf.args}):flatten():totable() or nil,
      filetypes = conf.filetypes,
      init_options = conf.init_options,
      settings = conf.settings
    }

    local config =
      vim.iter(overrides):filter(
      function(_, val)
        return val ~= nil
      end
    ):totable()
    vim.lsp.config(config)

    if vim.fn.executable(conf.bin) ~= 0 then
      vim.lsp.enable(name)
    end
  end
end)()
