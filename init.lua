vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.wrap = false
-- Enable wrap for specific file types
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "tex" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true  -- Break at word boundaries
	end,
})

vim.o.signcolumn = "yes"
vim.o.winborder = "rounded"

vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4

vim.pack.add({
	{ src="https://github.com/rebelot/kanagawa.nvim" },
	{ src="https://github.com/neovim/nvim-lspconfig" },
	{ src="https://github.com/nvim-mini/mini.nvim" },
	{ src="https://github.com/stevearc/oil.nvim" },
	{ src="https://github.com/akinsho/toggleterm.nvim" },
	{ src="https://github.com/lewis6991/gitsigns.nvim" },
	{ src="https://github.com/HakonHarnes/img-clip.nvim" },
	{ 
		src="https://github.com/iamcco/markdown-preview.nvim",
		hooks = {
			post_install = function()
				vim.fn["mkdp#util#install"]()
			end,
			post_update = function()
				vim.fn["mkdp#util#install"]()
			end,
		}
	},
})

vim.cmd.colorscheme("kanagawa-wave")
-- vim.cmd.colorscheme("kanagawa-dragon")

require("gitsigns").setup({
	signs = {
		add          = { text = '+' },
		change       = { text = '│' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	},
	signs_staged = {
		add          = { text = '+' },
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

require("img-clip").setup({
    default = {
        -- Save in the same directory as the file
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

require("mini.pick").setup({
    options = {
        use_cache = true,
    },
    window = {
        config = function()
            local height = math.floor(0.618 * vim.o.lines)
            local width = math.floor(0.618 * vim.o.columns)
            return {
                anchor = 'NW',
                height = height,
                width = width,
                row = math.floor(0.5 * (vim.o.lines - height)),
                col = math.floor(0.5 * (vim.o.columns - width)),
            }
        end,
    },
})
require("mini.icons").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()

-- Opening files with default application + setting up oil + making oil able to also open files with default application
local open_cmd = vim.fn.has("win32") == 1 and 'start ""' or "xdg-open"
vim.keymap.set("n", "<leader>o", ":!" .. open_cmd .. " %<CR><CR>", { desc = "Open in default app" })
require("oil").setup({
    columns = {
		"icon",
		"permissions",
		"size",
	},
	view_options = {
		show_hidden = true
	},
	keymaps = {
		["<leader>o"] = {
			callback = function()
				local oil = require("oil")
				local entry = oil.get_cursor_entry()
				local dir = oil.get_current_dir()
				if entry and dir then
					local filepath = dir .. entry.name
					vim.fn.system(open_cmd .. ' "' .. filepath .. '"')
				end
			end,
			desc = "Open with system app"
		}
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

-- Using default vim for autocompletion
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
		vim.keymap.set('n', 'nd', vim.lsp.buf.definition, opts)          -- Go to Definition
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)                -- Hover Documentation
		vim.keymap.set('n', 'nr', vim.lsp.buf.references, opts)          -- Go to References
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)	     -- Rename
		vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code Action
	end,
})
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 10
vim.opt.updatetime = 500

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

vim.keymap.set("n", "<leader>mp", ":MarkdownPreview<CR>", { desc = "Markdown preview" })

-- For formatting, just in case I want it on for some reason
-- vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)

-- More gitsigns shit here: https://github.com/lewis6991/gitsigns.nvim?tab=readme-ov-file#-keymaps
vim.keymap.set("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
vim.keymap.set("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
vim.keymap.set("n", "<leader>hS", ":Gitsigns stage_buffer<CR>")
vim.keymap.set("n", "<leader>hR", ":Gitsigns reset_buffer<CR>")
vim.keymap.set("n", "<leader>hp", ":Gitsigns preview_hunk_inline<CR>")
vim.keymap.set("n", "]c", function()
	if vim.wo.diff then
		vim.cmd.normal({']c', bang = true})
	else
		require('gitsigns').nav_hunk('next')
	end
end, { desc = "Next hunk" })
vim.keymap.set("n", "[c", function()
	if vim.wo.diff then
		vim.cmd.normal({'[c', bang = true})
	else
		require('gitsigns').nav_hunk('prev')
	end
end, { desc = "Previous hunk" })

vim.keymap.set("n", "<leader>e", ":Oil<CR>")


vim.keymap.set("n", "<leader>f", function()
    require('mini.pick').builtin.files({ tool = 'rg' })
end)
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>g", ":Pick grep<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
