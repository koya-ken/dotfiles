vim.cmd([[
  set number
  set relativenumber
  set expandtab
  set tabstop=4
  set shiftwidth=4
  set softtabstop=4
  set list
  set listchars=tab:»-,trail:•,space:·,nbsp:␣
  colorscheme elflord

  set cursorline
  set cursorcolumn

  " 横線（CursorLine）と縦線（CursorColumn）の色を控えめな暗いグレーに設定
  highlight CursorLine   cterm=NONE ctermbg=236 guibg=#2e3440
  highlight CursorColumn cterm=NONE ctermbg=236 guibg=#2e3440

  set termguicolors
" === 補完メニュー全体のカスタマイズ ===
  " Pmenu: 補完ウインドウ全体の背景と文字色（深い紺色の背景に、明るいグレーの文字）
  highlight Pmenu      guibg=#1e2433 guifg=#cdced1 ctermbg=235 ctermfg=252
  " PmenuSel: 現在選択している候補の背景と文字色（鮮やかな青背景に白文字）
  highlight PmenuSel   guibg=#2b3b59 guifg=#ffffff ctermbg=24  ctermfg=15
  " PmenuSbar: 補完ウインドウのスクロールバーの背景
  highlight PmenuSbar  guibg=#1a1f29 ctermbg=234
  " PmenuThumb: スクロールバーのつまみの色
  highlight PmenuThumb guibg=#3b4252 ctermbg=237
]])

-- インサートモード（挿入モード）で jj を叩いたら ESC（ノーマルモードに戻る）
vim.keymap.set('i', 'jj', '<Esc>', { silent = true })

-- 1文字削除（x）でヤンクしない
vim.keymap.set({'n', 'v'}, 'x', '"_x', { noremap = true, silent = true })
-- 削除（d）でヤンクしない
vim.keymap.set({'n', 'v'}, 'd', '"_d', { noremap = true, silent = true })
-- 行削除（dd）でヤンクしない
vim.keymap.set('n', 'dd', '"_dd', { noremap = true, silent = true })
-- 変更（c）でヤンクしない
vim.keymap.set({'n', 'v'}, 'c', '"_c', { noremap = true, silent = true })

vim.diagnostic.config({
    virtual_text = true, 
    signs = true,
    underline = true,
    update_in_insert = false, 
})

-- ==========================================
-- 2. lazy.nvim（プラグインマネージャー）の初期化
-- ==========================================
-- lazy.nvim 自体が存在しない場合は自動でダウンロードするコード
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================
-- 3. プラグインのインストールとLSPの設定
-- ==========================================

require("lazy").setup({
  
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSPの補完候補をcmpに渡すプラグイン
      "hrsh7th/cmp-buffer",   -- 開いているファイル内の単語も補完に出す
      "hrsh7th/cmp-path",     -- ファイルパスを補完に出す
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        -- 補完の表示方法
        matching = {
          disallow_fuzzy_matching = false,
          disallow_full_matching = false,
          disallow_partial_fuzzy_matching = false,
          disallow_partial_matching = false,
          disallow_prefix_unmatching = false,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 1000 },
          { name = 'buffer', priority = 500 },
          { name = 'path', priority = 250 },
        })
      })
    end
  },

-- ★ 入力中に引数を「常に自動表示」させる
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {
      bind = true,
      handler_opts = {
        border = "rounded"
      },
      hint_enable = true,
      hint_prefix = " ",
      floating_window = true,
      floating_window_above_cur = true,
    },
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end
  },

  -- LSPの設定（Ruff）
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- nvim-cmp（補完）とLSPを連携させるための準備
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- 公式ドキュメント推奨の Neovim 0.11+ 向け設定
      vim.lsp.config('ruff', {
          cmd = { "ruff", "server" },
          root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
          filetypes = { "python" },
          capabilities = capabilities,
      })
      vim.lsp.enable('ruff')

      local python_path = ""

      -- Windows（LoopやJITの判定で "Windows" または "Win32" になる）
      if vim.uv.os_uname().sysname:find("Windows") then
          python_path = ".venv/Scripts/python.exe"
      else
          -- Linux や macOS など（UNIX系環境）
          python_path = ".venv/bin/python"
      end
      settings = {
          python = {
          }
      }
        vim.lsp.config("basedpyright", {
        cmd = { "basedpyright-langserver", "--stdio" },
        root_markers = { '.venv', '.git', 'pyproject.toml', 'setup.py' },
        filetypes = { "python" },
        capabilities = capabilities,
        settings = {
          basedpyright = {
            analysis = {
              useLibraryCodeForTypes = false,
              typeCheckingMode = "standard",
              diagnosticMode = "openFilesOnly",
            },
            python = {
              pythonPath = python_path,
            }
          }
        }
      })
       -- pytorch等一部でうまく動かなかった
      -- vim.lsp.enable('basedpyright')

vim.lsp.config("jedi", {
        cmd = { "jedi-language-server" },
        filetypes = { "python" },
        root_markers = { '.venv', '.git', 'pyproject.toml' },
        capabilities = capabilities,
        init_options = {
          workspace = {
            environmentPath = python_path,
          },
          completion = {
            -- 補完のスニエット（引数の自動入力など）を有効化
            disableSnippets = false,
          }
        }
      })
      vim.lsp.enable('jedi')

      -- Ruff接続時の自動化設定
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "ruff" then
            local bufnr = args.buf

            -- 保存時自動フォーマット＆修正
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
                vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })

    end
  },
{
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      -- ミニマップの基本設定
      local map = require('mini.map')
      map.setup({
        -- 画面の右側に表示する設定（デフォルト）
        side = 'right',
        -- ミニマップの幅（文字数）
        width = 20,
        -- 何を表示するか（コードの形、選択範囲、LSPのエラーなどを統合）
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.diff(),
          map.gen_integration.diagnostic(),
        },
      })

      -- 最初からミニマップを開く
      map.open()
    end
  },
})
