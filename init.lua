vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.wrap = false
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "tex" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

vim.o.signcolumn = "yes"
vim.o.winborder = "rounded"

vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4

vim.o.updatetime = 500

vim.pack.add({
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/nvim-mini/mini.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/akinsho/toggleterm.nvim" },
	{ src = "https://github.com/HakonHarnes/img-clip.nvim" },
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("^1"),
	},
	{
		src = "https://github.com/iamcco/markdown-preview.nvim",
		hooks = {
			post_install = function()
				vim.fn["mkdp#util#install"]()
			end,
			post_update = function()
				vim.fn["mkdp#util#install"]()
			end,
		},
	},
})

-- ─── Colorscheme ──────────────────────────────────────────────────────────────

vim.cmd.colorscheme("kanagawa-wave")
-- vim.cmd.colorscheme("kanagawa-dragon")

-- ─── Gitsigns ─────────────────────────────────────────────────────────────────

require("gitsigns").setup({
	signs = {
		add          = { text = "+" },
		change       = { text = "│" },
		delete       = { text = "_" },
		topdelete    = { text = "‾" },
		changedelete = { text = "~" },
		untracked    = { text = "┆" },
	},
	signs_staged = {
		add          = { text = "+" },
		change       = { text = "│" },
		delete       = { text = "_" },
		topdelete    = { text = "‾" },
		changedelete = { text = "~" },
		untracked    = { text = "┆" },
	},
})

-- ─── Toggleterm ───────────────────────────────────────────────────────────────

require("toggleterm").setup({
	open_mapping = [[<c-\>]],
	autochdir    = true,
	direction    = "float",
})

-- ─── img-clip ─────────────────────────────────────────────────────────────────

require("img-clip").setup({
	default = {
		dir_path = ".",
		relative_to_current_file = true,
		prompt_for_file_name = false,
		file_name = function()
			local current_file = vim.fn.expand("%:t:r")
			local clean_name = current_file:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
			local time = os.date("%Y-%m-%d-%H-%M-%S")
			return clean_name .. "-" .. time
		end,
	},
	filetypes = {
		markdown = {
			url_encode_path = false,
			template = "![$CURSOR]($FILE_PATH)",
			download_images = false,
		},
	},
})
vim.keymap.set("n", "<leader>p", ":PasteImage<CR>", { desc = "Paste image from clipboard" })

-- ─── mini.nvim ────────────────────────────────────────────────────────────────

require("mini.pick").setup({
	options = { use_cache = true },
	window = {
		config = function()
			local height = math.floor(0.618 * vim.o.lines)
			local width  = math.floor(0.618 * vim.o.columns)
			return {
				anchor = "NW",
				height = height,
				width  = width,
				row    = math.floor(0.5 * (vim.o.lines - height)),
				col    = math.floor(0.5 * (vim.o.columns - width)),
			}
		end,
	},
})
require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()

-- ─── Oil ──────────────────────────────────────────────────────────────────────

local open_cmd = vim.fn.has("win32") == 1 and 'start ""' or "xdg-open"
vim.keymap.set("n", "<leader>o", ":!" .. open_cmd .. " %<CR><CR>", { desc = "Open in default app" })

require("oil").setup({
	columns = { "icon", "permissions", "size" },
	view_options = { show_hidden = true },
	keymaps = {
		["<leader>o"] = {
			callback = function()
				local oil   = require("oil")
				local entry = oil.get_cursor_entry()
				local dir   = oil.get_current_dir()
				if entry and dir then
					vim.fn.system(open_cmd .. ' "' .. dir .. entry.name .. '"')
				end
			end,
			desc = "Open with system app",
		},
	},
})

-- ─── LSP ──────────────────────────────────────────────────────────────────────

-- Server configs: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
local servers = { "clangd", "lua_ls", "pyright", "gdscript", "gdshader_lsp" }
vim.lsp.enable(servers)

vim.diagnostic.config({
	virtual_text  = true,
	signs         = true,
	underline     = true,
	update_in_insert = false,
})

-- Disable diagnostics for C/C++ by default; use <leader>td to toggle
local cpp_diagnostics_state = {}

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "clangd" then
			local bufnr = args.buf
			cpp_diagnostics_state[bufnr] = false
			vim.diagnostic.config({
				virtual_text = false,
				signs        = false,
				underline    = false,
			}, vim.lsp.diagnostic.get_namespace(client.id))
		end
	end,
})

local function toggle_diagnostics()
	local bufnr  = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	local clangd_client = nil
	for _, client in ipairs(clients) do
		if client.name == "clangd" then
			clangd_client = client
			break
		end
	end

	if not clangd_client then
		print("Toggle diagnostics only works for C/C++ files")
		return
	end

	cpp_diagnostics_state[bufnr] = not cpp_diagnostics_state[bufnr]
	local ns = vim.lsp.diagnostic.get_namespace(clangd_client.id)

	if cpp_diagnostics_state[bufnr] then
		vim.diagnostic.config({ virtual_text = true, signs = true, underline = true }, ns)
	else
		vim.diagnostic.config({ virtual_text = false, signs = false, underline = false }, ns)
	end
end

vim.keymap.set("n", "<leader>td", toggle_diagnostics, { desc = "Toggle diagnostics (C/C++)" })

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then return end

		local opts = { buffer = args.buf, silent = true }
		vim.keymap.set("n", "nd",         vim.lsp.buf.definition,  opts)
		vim.keymap.set("n", "K",          vim.lsp.buf.hover,        opts)
		vim.keymap.set("n", "nr",         vim.lsp.buf.references,   opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,       opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,  opts)
	end,
})

-- ─── blink.cmp ────────────────────────────────────────────────────────────────

require("blink.cmp").setup({
	keymap = {
		preset = "default",
		["<C-]>"] = { function(cmp)
			cmp.hide()
			vim.lsp.buf.definition()
			return true
		end },
	},
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		documentation = { auto_show = true },
	},
	sources = {
		default = { "lsp", "path", "buffer" },
	},
	fuzzy = { implementation = "prefer_rust_with_warning" },
})

vim.opt.pumheight = 10

-- ─── Keymaps ──────────────────────────────────────────────────────────────────

vim.keymap.set("v", "/", 'y/\\V<C-R>=escape(@",\'/\\\')<CR><CR>', { desc = "Search visual selection" })

vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>')
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>')

vim.keymap.set("n", "<leader>mp", ":MarkdownPreview<CR>",  { desc = "Markdown preview" })

-- Gitsigns
vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
vim.keymap.set("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
vim.keymap.set("n", "<leader>hS", ":Gitsigns stage_buffer<CR>")
vim.keymap.set("n", "<leader>hR", ":Gitsigns reset_buffer<CR>")
vim.keymap.set("n", "<leader>hp", ":Gitsigns preview_hunk_inline<CR>")
vim.keymap.set("n", "]c", function()
	if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
	else require("gitsigns").nav_hunk("next") end
end, { desc = "Next hunk" })
vim.keymap.set("n", "[c", function()
	if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
	else require("gitsigns").nav_hunk("prev") end
end, { desc = "Previous hunk" })

-- Oil / file navigation
vim.keymap.set("n", "<leader>e", ":Oil<CR>")

-- mini.pick
vim.keymap.set("n", "<leader>f", function()
	require("mini.pick").builtin.files({ tool = "rg" })
end)
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>g", ":Pick grep<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")

-- ─── Pack clean ───────────────────────────────────────────────────────────────

local function pack_clean()
	local active  = {}
	local unused  = {}
	for _, plugin in ipairs(vim.pack.get()) do
		active[plugin.spec.name] = plugin.active
	end
	for _, plugin in ipairs(vim.pack.get()) do
		if not active[plugin.spec.name] then
			table.insert(unused, plugin.spec.name)
		end
	end
	if #unused == 0 then
		print("No unused plugins.")
		return
	end
	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then vim.pack.del(unused) end
end

vim.keymap.set("n", "<leader>pc", pack_clean, { desc = "Pack clean" })
