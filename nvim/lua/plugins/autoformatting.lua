return {
  'nvimtools/none-ls.nvim',
  dependencies = {
    'nvimtools/none-ls-extras.nvim',
    'jayp0521/mason-null-ls.nvim',
  },
  config = function()
    local null_ls = require('null-ls')
    local diagnostics = null_ls.builtins.diagnostics
    local formatting = null_ls.builtins.formatting

    -- Define cpplint as a custom source
    local cpplint = {
      method = null_ls.methods.DIAGNOSTICS,
      filetypes = { 'cpp', 'c' },
      generator = null_ls.generator({
        command = '/usr/bin/cpplint',
        args = { '--quiet', '$FILENAME' },
        format = 'line',
        to_stdin = false,
        from_stderr = true,
        on_output = function(line, params)
          local pattern = ':(%d+):(%d+):%s+(.*)'
          local line_num, col_num, message = line:match(pattern)
          if line_num and col_num and message then
            return {
              row = tonumber(line_num),
              col = tonumber(col_num),
              message = message,
              source = 'cpplint',
            }
          end
        end,
      }),
    }

    -- Define clang_tidy as a custom source
    local clang_tidy = {
      method = null_ls.methods.DIAGNOSTICS,
      filetypes = { 'cpp', 'c' },
      generator = null_ls.generator({
        command = '/usr/bin/clang-tidy',
        args = { '--quiet', '$FILENAME' },
        format = 'line',
        to_stdin = false,
        from_stderr = true,
        on_output = function(line, params)
          local pattern = ':(%d+):(%d+):%s+(.*)'
          local line_num, col_num, message = line:match(pattern)
          if line_num and col_num and message then
            return {
              row = tonumber(line_num),
              col = tonumber(col_num),
              message = message,
              source = 'clang-tidy',
            }
          end
        end,
      }),
    }

    -- Define sources
    local sources = {
      -- C/C++
      cpplint,
      clang_tidy,
      formatting.clang_format.with({ command = '/usr/bin/clang-format' }),

      -- JavaScript/TypeScript
      -- Use conditional registration for eslint
      function()
        local eslint = require("none-ls.diagnostics.eslint")
        return eslint.with({
          command = '/usr/bin/eslint_d',
          condition = function(utils)
            return utils.root_has_file({
              '.eslintrc.js',
              '.eslintrc.cjs',
              '.eslintrc.yaml',
              '.eslintrc.yml',
              '.eslintrc.json'
            })
          end,
        })
      end,

      formatting.prettier.with({
        command = '/usr/bin/prettier',
        filetypes = {
          'javascript',
          'typescript',
          'javascriptreact',
          'typescriptreact',
          'json',
          'html',
          'yaml',
          'markdown'
        },
      }),

      -- Lua
      formatting.stylua.with({ command = '/usr/bin/stylua' }),

      -- Shell
      formatting.shfmt.with({ command = '/usr/bin/shfmt', args = { '-i', '4' } }),
    }

    -- Format on save
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    null_ls.setup({
      sources = sources,
      on_attach = function(client, bufnr)
        if client.supports_method('textDocument/formatting') then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
      end,
    })
  end,
}

