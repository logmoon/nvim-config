vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false

vim.o.signcolumn = "yes"
vim.o.winborder = "rounded"

vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4

vim.pack.add({
	{ src="https://github.com/folke/tokyonight.nvim" },
	{ src="https://github.com/neovim/nvim-lspconfig" },
	{ src="https://github.com/nvim-mini/mini.nvim" },
	{ src="https://github.com/stevearc/oil.nvim" },
	{ src="https://github.com/akinsho/toggleterm.nvim" },
	{ src="https://github.com/lewis6991/gitsigns.nvim" },
	{ src="https://github.com/tpope/vim-fugitive" },
})

require("gitsigns").setup({
	signs = {
		add          = { text = '│' },
		change       = { text = '│' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	},
	signs_staged = {
		add          = { text = '│' },
		change       = { text = '│' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	}
})

require("toggleterm").setup({
	open_mapping = [[<c-\>]], -- Toggle with Ctrl+\
	direction = "float"
})

require("mini.pick").setup()
require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()

require("oil").setup({
    columns = {
		"icon",
		"permissions",
		"size",
	},
	view_options = {
		show_hidden = true
	}
})

-- LSP Server configs: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
local servers = { "clangd", "lua_ls", "pyright" }
vim.lsp.enable(servers)

-- Disable diagnostics by default cuz they piss me off
vim.diagnostic.config({
	virtual_text = false,
	signs = false,
	underline = false,
	update_in_insert = false,
})

vim.cmd.colorscheme("tokyonight-night")

local diagnostics_active = false
local function toggle_diagnostics()
	diagnostics_active = not diagnostics_active
	if diagnostics_active then
		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			underline = true,
		})
	else
		vim.diagnostic.config({
			virtual_text = false,
			signs = false,
			underline = false,
		})
	end
end
vim.keymap.set("n", "<leader>td", toggle_diagnostics, { desc = "Toggle diagnostics" })

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then return end
		
		local bufnr = args.buf
		
		if client.server_capabilities.completionProvider then
			vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
		end
		
		local opts = { buffer = bufnr, silent = true }
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)          -- Go to Definition
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)                -- Hover Documentation
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)          -- Go to References
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)	     -- Rename
		vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code Action
	end,
})

vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

vim.opt.pumheight = 10
vim.opt.updatetime = 300

local function pack_clean()
	local active_plugins = {}
	local unused_plugins = {}

	for _, plugin in ipairs(vim.pack.get()) do
		active_plugins[plugin.spec.name] = plugin.active
	end

	for _, plugin in ipairs(vim.pack.get()) do
		if not active_plugins[plugin.spec.name] then
			table.insert(unused_plugins, plugin.spec.name)
		end
	end

	if #unused_plugins == 0 then
		print("No unused plugins.")
		return
	end

	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then
		vim.pack.del(unused_plugins)
	end
end
vim.keymap.set("n", "<leader>pc", pack_clean)

vim.keymap.set({"n", "v", "x"}, "<leader>y", '"+y<CR>')
vim.keymap.set({"n", "v", "x"}, "<leader>d", '"+d<CR>')

-- For formatting, just in case I want it on for some reason
-- vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)

-- More gitsigns shit here: https://github.com/lewis6991/gitsigns.nvim?tab=readme-ov-file#-keymaps
vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
vim.keymap.set("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
vim.keymap.set("n", "<leader>hS", ":Gitsigns stage_buffer<CR>")
vim.keymap.set("n", "<leader>hR", ":Gitsigns reset_buffer<CR>")

vim.keymap.set("n", "<leader>hp", ":Gitsigns preview_hunk<CR>")
vim.keymap.set("n", "<leader>tb", ":Gitsigns preview_toggle_current_line_blame<CR>")

vim.keymap.set("n", "<leader>e", ":Oil<CR>")

vim.keymap.set("n", "<leader>f", ":Pick files<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
vim.keymap.set("n", "<leader>g", ":Pick grep<CR>")
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
