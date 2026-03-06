vim.g.mapleader = " "

vim.o.number         = true
vim.o.relativenumber = true
vim.o.wrap           = false
vim.o.signcolumn     = "yes"
vim.o.winborder      = "rounded"
vim.o.expandtab      = false
vim.o.shiftwidth     = 4
vim.o.softtabstop    = 4
vim.o.tabstop        = 4
vim.o.updatetime     = 500

vim.api.nvim_create_autocmd("FileType", {
	pattern  = { "markdown", "text", "tex" },
	callback = function()
		vim.opt_local.wrap      = true
		vim.opt_local.linebreak = true
	end,
})

vim.pack.add({
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/nvim-mini/mini.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/akinsho/toggleterm.nvim" },
	{ src = "https://github.com/HakonHarnes/img-clip.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{
		src     = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("^1"),
	},
	{
		src   = "https://github.com/iamcco/markdown-preview.nvim",
		hooks = {
			post_install = function() vim.fn["mkdp#util#install"]() end,
			post_update  = function() vim.fn["mkdp#util#install"]() end,
		},
	},
})

-- ─── Colorscheme ──────────────────────────────────────────────────────────────

vim.cmd.colorscheme("kanagawa-wave")

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

require("toggleterm").setup({ direction = "float" })

local float_term = nil

vim.keymap.set({ "n", "t" }, [[<c-\>]], function()
    if float_term and float_term:is_open() then
        float_term:close()
    elseif float_term then
        float_term:open()
    else
        local dir
        if vim.bo.filetype == "oil" then
            dir = require("oil").get_current_dir() or vim.fn.getcwd()
        else
            dir = vim.fn.expand("%:p:h")
        end
        float_term = require("toggleterm.terminal").Terminal:new({
            dir           = dir,
            close_on_exit = true,
            on_exit       = function() float_term = nil end,
        })
        float_term:open()
    end
end)

local last_dir = vim.fn.getcwd()

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    callback = function()
        if vim.bo.buftype ~= "terminal" then
            if vim.bo.filetype == "oil" then
                last_dir = require("oil").get_current_dir() or vim.fn.getcwd()
            else
                local d = vim.fn.expand("%:p:h")
                if d and #d > 0 then last_dir = d end
            end
        end
    end,
})

vim.keymap.set("t", [[<c-[>]], function()
    if not float_term or not float_term:is_open() then return end
    float_term:send("cd " .. vim.fn.shellescape(last_dir))
end)

-- ─── img-clip ─────────────────────────────────────────────────────────────────

require("img-clip").setup({
	default = {
		dir_path              = ".",
		relative_to_current_file = true,
		prompt_for_file_name  = false,
		file_name = function()
			local name = vim.fn.expand("%:t:r"):lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
			return name .. "-" .. os.date("%Y-%m-%d-%H-%M-%S")
		end,
	},
	filetypes = {
		markdown = {
			url_encode_path  = false,
			template         = "![$CURSOR]($FILE_PATH)",
			download_images  = false,
		},
	},
})

-- ─── mini.nvim ────────────────────────────────────────────────────────────────

require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()

-- ─── Oil ──────────────────────────────────────────────────────────────────────

local open_cmd = vim.fn.has("win32") == 1 and 'start ""' or "xdg-open"

require("oil").setup({
	columns      = { "icon", "permissions", "size" },
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

-- ─── Telescope ────────────────────────────────────────────────────────────────

require("telescope").setup()

-- ─── LSP ──────────────────────────────────────────────────────────────────────

vim.lsp.enable({ "clangd", "lua_ls", "pyright", "gdscript", "gdshader_lsp" })

vim.diagnostic.config({
	virtual_text     = true,
	signs            = true,
	underline        = true,
	update_in_insert = false,
})

local cpp_diag_state = {}

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "clangd" then
			cpp_diag_state[args.buf] = false
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
	local client = nil
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if c.name == "clangd" then client = c break end
	end
	if not client then print("Toggle diagnostics only works for C/C++ files") return end

	cpp_diag_state[bufnr] = not cpp_diag_state[bufnr]
	local ns = vim.lsp.diagnostic.get_namespace(client.id)
	local on = cpp_diag_state[bufnr]
	vim.diagnostic.config({ virtual_text = on, signs = on, underline = on }, ns)
end

vim.api.nvim_create_autocmd("LspAttach", {
	group    = vim.api.nvim_create_augroup("my.lsp", { clear = true }),
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
		preset  = "default",
		["<C-]>"] = { function(cmp) cmp.hide() vim.lsp.buf.definition() return true end },
	},
	appearance = { nerd_font_variant = "mono" },
	completion = { documentation = { auto_show = true } },
	sources    = { default = { "lsp", "path", "buffer" } },
	fuzzy      = { implementation = "prefer_rust_with_warning" },
})

vim.opt.pumheight = 10

-- ─── Keymaps ──────────────────────────────────────────────────────────────────

vim.keymap.set("v", "/", 'y/\\V<C-R>=escape(@",\'/\\\')<CR><CR>')

vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>')
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>')

vim.keymap.set("n", "<leader>mp", ":MarkdownPreview<CR>")
vim.keymap.set("n", "<leader>p",  ":PasteImage<CR>")
vim.keymap.set("n", "<leader>dt", toggle_diagnostics)
vim.keymap.set("n", "<leader>e",  ":Oil<CR>")
vim.keymap.set("n", "<leader>o",  ":!" .. open_cmd .. " %<CR><CR>")

vim.keymap.set("n", "<leader>f",  require("telescope.builtin").find_files)
vim.keymap.set("n", "<leader>b",  require("telescope.builtin").buffers)
vim.keymap.set("n", "<leader>h",  require("telescope.builtin").help_tags)
vim.keymap.set("n", "<leader>g",  require("telescope.builtin").live_grep)

vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
vim.keymap.set("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
vim.keymap.set("n", "<leader>hS", ":Gitsigns stage_buffer<CR>")
vim.keymap.set("n", "<leader>hR", ":Gitsigns reset_buffer<CR>")
vim.keymap.set("n", "<leader>hp", ":Gitsigns preview_hunk_inline<CR>")
vim.keymap.set("n", "]c", function()
	if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
	else require("gitsigns").nav_hunk("next") end
end)
vim.keymap.set("n", "[c", function()
	if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
	else require("gitsigns").nav_hunk("prev") end
end)

-- ─── Pack clean ───────────────────────────────────────────────────────────────

local function pack_clean()
	local active = {}
	for _, p in ipairs(vim.pack.get()) do active[p.spec.name] = p.active end
	local unused = {}
	for _, p in ipairs(vim.pack.get()) do
		if not active[p.spec.name] then table.insert(unused, p.spec.name) end
	end
	if #unused == 0 then print("No unused plugins.") return end
	if vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2) == 1 then
		vim.pack.del(unused)
	end
end

vim.keymap.set("n", "<leader>pc", pack_clean)

-- ─── Base ─────────────────────────────────────────────────────────────────────

dofile(vim.fn.expand("~/base/tools/nvim/base.lua"))
