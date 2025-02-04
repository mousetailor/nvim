return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'j-hui/fidget.nvim',
    'folke/neodev.nvim',
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'L3MON4D3/LuaSnip',
    'rafamadriz/friendly-snippets',

    -- New plugins
    'p00f/clangd_extensions.nvim', -- Enhanced clangd features
    'mfussenegger/nvim-dap',       -- Debugging
    'rcarriga/nvim-dap-ui',        -- Debug UI
    'nvim-neotest/nvim-nio',       -- Required by nvim-dap-ui
    'windwp/nvim-ts-autotag',      -- Auto close/rename HTML tags
    'windwp/nvim-autopairs',       -- Auto close brackets/quotes
    'norcalli/nvim-colorizer.lua', -- Color highlighter for CSS
  },
  config = function()
    -- Initialize required components
    require('neodev').setup()
    require('fidget').setup({
      progress = {
        display = {
          done_icon = "✓",
        },
      },
      notification = {
        window = {
          winblend = 0,
        },
      },
    })

    local mason = require('mason')
    local mason_lspconfig = require('mason-lspconfig')
    local mason_tool_installer = require('mason-tool-installer')

    -- Mason setup
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    })

    -- nvim-cmp setup
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    require('luasnip.loaders.from_vscode').lazy_load()
    luasnip.config.setup {}

    local kind_icons = {
      Text = '󰉿',
      Method = 'm',
      Function = '󰊕',
      Constructor = '',
      Field = '',
      Variable = '󰆧',
      Class = '󰌗',
      Interface = '',
      Module = '',
      Property = '',
      Unit = '',
      Value = '󰎠',
      Enum = '',
      Keyword = '󰌋',
      Snippet = '',
      Color = '󰏘',
      File = '󰈙',
      Reference = '',
      Folder = '󰉋',
      EnumMember = '',
      Constant = '󰇽',
      Struct = '',
      Event = '',
      Operator = '󰆕',
      TypeParameter = '󰊄',
    }

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-c>'] = cmp.mapping.complete({}),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
      },
      formatting = {
        fields = { 'kind', 'abbr', 'menu' },
        format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind = string.format('%s', kind_icons[vim_item.kind])
          -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
          vim_item.menu = ({
            nvim_lsp = '[LSP]',
            luasnip = '[Snippet]',
            buffer = '[Buffer]',
            path = '[Path]',
          })[entry.source.name]
          return vim_item
        end,
      },
    })

    -- LSP settings
    local lspconfig = require('lspconfig')
    local on_attach = function(client, bufnr)
      local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

      -- LSP Keymaps
      nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
      nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
      nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
      nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
      nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
      nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
      nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
      nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
      nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- Workspace folders
      nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
      nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
      nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, '[W]orkspace [L]ist Folders')

      -- Create augroup for this buffer
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      -- Format on save
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr })
          end,
        })
      end

      -- Highlight references
      if client.server_capabilities.documentHighlightProvider then
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = bufnr,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = bufnr,
          callback = vim.lsp.buf.clear_references,
        })
      end
    end

    -- nvim-cmp supports additional completion capabilities
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Enable the following language servers
    local servers = {
      clangd = {}, -- C/C++
      -- tsserver = {}, -- TypeScript/JavaScript
      html = { filetypes = { 'html', 'twig', 'hbs' } },
      cssls = {},
      tailwindcss = {},
      eslint = {},
      lua_ls = {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    -- Setup mason-lspconfig
    mason_lspconfig.setup({
      ensure_installed = vim.tbl_keys(servers),
      automatic_installation = true,
    })

    mason_lspconfig.setup_handlers({
      function(server_name)
        local server_config = servers[server_name] or {}
        server_config.capabilities = capabilities
        server_config.on_attach = on_attach
        lspconfig[server_name].setup(server_config)
      end,
    })

    -- Mason Tool Installer setup
    mason_tool_installer.setup({
      ensure_installed = {
        'clangd',                     -- C/C++ LSP
        'typescript-language-server', -- TypeScript LSP
        'clang-format',               -- C/C++ formatter
        'prettier',                   -- Web formatter
        'stylua',                     -- Lua formatter
        'eslint_d',                   -- JavaScript linter
        'cpplint',                    -- C/C++ linter
      },
      auto_update = true,
      run_on_start = true,
    })

    -- Configure clangd_extensions.nvim
    require('clangd_extensions').setup({
      inlay_hints = {
        inline = true, -- Show inlay hints inline
      },
    })

    -- Configure nvim-dap (Debug Adapter Protocol)
    local dap = require('dap')
    dap.adapters.lldb = {
      type = 'executable',
      command = '/usr/bin/lldb-vscode', -- Path to lldb-vscode
      name = 'lldb',
    }
    dap.configurations.cpp = {
      {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
    }

    -- Configure nvim-dap-ui
    require('dapui').setup()

    -- Configure nvim-ts-autotag (Auto close/rename HTML tags)
    require('nvim-ts-autotag').setup()

    -- Configure nvim-autopairs (Auto close brackets/quotes)
    require('nvim-autopairs').setup()

    -- Configure nvim-colorizer.lua (Color highlighter for CSS)
    require('colorizer').setup()
  end,
}
