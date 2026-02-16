-- === Neovim Config ===

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- === Options ===
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- OSC 52 clipboard (works over SSH + tmux, Neovim 0.10+)
if os.getenv("SSH_CONNECTION") or os.getenv("TMUX") then
  local ok, osc52 = pcall(function() return require("vim.ui.clipboard.osc52") end)
  if ok then
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
        ["*"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
      },
    }
  end
end

opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = "menuone,noselect"
opt.showmode = false
opt.laststatus = 3  -- global statusline

-- === Keymaps ===
local map = vim.keymap.set

-- Better navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left pane" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower pane" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper pane" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right pane" })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Clear search highlight
map("n", "<Esc>", ":noh<CR>", { silent = true })

-- Better paste (don't yank replaced text)
map("x", "<leader>p", '"_dP')

-- Quick save/quit
map("n", "<leader>w", ":w<CR>", { desc = "Save" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Buffers
map("n", "<S-h>", ":bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>x", ":bdelete<CR>", { desc = "Close buffer" })

-- === Plugins ===
require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "night", transparent = true })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = "",
          section_separators = "",
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
      { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>r", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    },
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
    },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
        renderer = { icons = { show = { file = true, folder = true, git = true } } },
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local langs = { "lua", "python", "javascript", "typescript", "rust", "json", "yaml", "toml", "bash", "markdown" }
      vim.treesitter.language.register("bash", "zsh")
      for _, lang in ipairs(langs) do
        pcall(vim.treesitter.language.add, lang)
      end
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "ts_ls", "rust_analyzer", "lua_ls" },
      })
      local servers = { "pyright", "ts_ls", "rust_analyzer", "lua_ls" }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, {})
      end
      vim.lsp.enable(servers)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bmap = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
          end
          bmap("gd", vim.lsp.buf.definition, "Go to definition")
          bmap("gr", vim.lsp.buf.references, "References")
          bmap("K", vim.lsp.buf.hover, "Hover")
          bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
          bmap("<leader>rn", vim.lsp.buf.rename, "Rename")
          bmap("<leader>d", vim.diagnostic.open_float, "Diagnostics")
        end,
      })
    end,
  },

  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "󰍵" },
        },
      })
    end,
  },

  -- Auto pairs
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },

  -- Comment
  { "numToStr/Comment.nvim", keys = { { "gcc", mode = "n" }, { "gc", mode = "v" } }, config = true },

  -- Indent guides
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", config = true },

  -- Which-key (shows keybinds)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({ delay = 500 })
    end,
  },

  -- Surround (cs"' to change " to ', ysiw" to wrap word in ")
  { "kylechui/nvim-surround", event = "VeryLazy", config = true },

  -- Better diagnostics list
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
    },
    config = true,
  },

  -- Todo comments (highlights TODO, FIXME, HACK etc)
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = true,
  },
}, {
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = false },
})
