vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
    -- Packer can manage itself
    use("wbthomason/packer.nvim")

    -- Telescope
    use({ "nvim-telescope/telescope.nvim", tag = "0.1.8", requires = { { "nvim-lua/plenary.nvim" } } })
    -- Treesitter
    use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
    -- Undotree
    use("mbbill/undotree")
    -- Nvim lsp
    use("neovim/nvim-lspconfig")
    use("EdenEast/nightfox.nvim")
    --Mason
    use("mason-org/mason.nvim")
    use("mason-org/mason-lspconfig.nvim")
    -- Nvim Completion
    use("hrsh7th/nvim-cmp")
    use({ "hrsh7th/cmp-nvim-lsp", requires = { { "rafamadriz/friendly-snippets" } } })
    use("L3MON4D3/LuaSnip")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")
    -- Formatting
    use("stevearc/conform.nvim")
    use("mfussenegger/nvim-lint")
    -- nvim game by ThePrimeagencomple
    use("ThePrimeagen/vim-be-good")
    --- local file explorer plugin
    use({ "~/.config/mNetrw" })

    use({
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons", -- optional, but recommended
        }
    })
    use("lukas-reineke/indent-blankline.nvim")
    use("vuciv/golf")

    -- gitsign --
    use("lewis6991/gitsigns.nvim")
    use ("sindrets/diffview.nvim" )
    use ("nyoom-engineering/oxocarbon.nvim")
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }
end)

