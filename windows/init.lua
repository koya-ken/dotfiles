vim.cmd([[
  set number
  set relativenumber
  set expandtab
  set tabstop=4
  set shiftwidth=4
  set softtabstop=4
  set autoread
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
-- ファイルのエンコーディング（文字コード）の自動判別順序を設定
vim.opt.fileencodings = "utf-8,cp932,euc-jp,sjis"

-- インサートモード（挿入モード）で jj を叩いたら ESC（ノーマルモードに戻る）
vim.keymap.set('i', 'jj', '<Esc>', { silent = true })
-- Space + q で現在のタブを閉じる (Tab Close)
vim.keymap.set('n', '<Space>q', ':tabclose<CR>', { silent = true, desc = 'Close current tab' })

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

if vim.fn.has("win32") == 1 then
  local powershell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
  
  vim.opt.shell = powershell
  vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

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
-- データベース操作クライアント
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod', lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    },
    cmd = { 'DBUI', 'DBUIToggle' },
    init = function()
      -- UIの表示カスタム
      vim.g.db_ui_show_database_navigation = 1


      -- 💡 1. DBファイルを開いたときに「新しいタブ」を開いてから自動でDBUIを起動する
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "*.db", "*.sqlite", "*.sqlite3" },
        callback = function(args)
          local filepath = vim.api.nvim_buf_get_name(args.buf):gsub("\\", "/")
          local filename = vim.fn.fnamemodify(filepath, ":t")

          vim.g.dbs = {
            [filename] = "sqlite:" .. filepath
          }

          local bufnr = args.buf
          vim.schedule(function()
            -- DBバイナリが表示されているバッファを先に消去
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_delete(bufnr, { force = true })
            end

            -- 新しいタブを開く
            vim.cmd("tabnew")
            -- 開いた新しいタブの中で DBUI を起動する
            vim.cmd("DBUI")
            -- このDB確認タブの中では Neo-tree は不要なので閉じる
            vim.cmd("Neotree close")
          end)
        end,
      })

      -- 💡 2. DB関連の画面内だけで、Ctrl+d を「タブを閉じる」キーにする
      vim.api.nvim_create_autocmd("FileType", {
        -- dbui（左サイドバー）と dbout（右側のクエリ結果表示）を対象にする
        pattern = { "dbui", "dbout" },
        callback = function(args)
          -- このバッファの中だけで有効な Ctrl+d キーマップを登録
          -- DBUI画面全体を終了し、現在のタブを完全に閉じます
          vim.keymap.set("n", "<C-d>", function()
            vim.cmd("DBUIClose")  -- DBUIの接続を閉じる
            vim.cmd("tabclose")   -- 現在のタブを閉じる
          end, { buffer = args.buf, silent = true })
        end,
      })

      -- 💡 3. 【新規追加】もしクエリ結果が変な場所（細長い左窓）で開かれたら、広い右窓へ自動で引っ越す
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(args)
          -- 開かれたバッファのFileTypeが "dbout"（クエリ結果）の場合のみ処理
          if vim.bo[args.buf].filetype == "dbout" then
            local win_width = vim.api.nvim_win_get_width(0)
            -- 現在のウィンドウ幅が40文字以下（＝細長いDBUIウィンドウ）の中で開かれてしまった場合
            if win_width <= 40 then
              vim.schedule(function()
                -- 一度その崩れた分割ウィンドウを閉じる
                vim.cmd("close")
                
                -- 右側の広いウィンドウ（通常は一番右のウィンドウ）に移動
                vim.cmd("wincmd l")
                
                -- 移動先（右側）でそのバッファを開き直す
                vim.cmd("buffer " .. args.buf)
              end)
            end
          end
        end,
      })
      -- 手動で開閉したい時のキーマップ（念のため残す）
      vim.keymap.set('n', '<Space>db', ':DBUIToggle<CR>', { silent = true })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",        -- 隠しファイルも含める（.env とか）
            "--glob=!**/.git/*" 
          },
        },
        pickers = {
          -- Ctrl+p で呼び出す find_files の挙動も個別で最適化
          find_files = {
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
          },
        },
      })

      -- キーマップの設定（Ctrl + p でファイル検索）
      vim.keymap.set('n', '<C-p>', require('telescope.builtin').find_files, {})
      -- 2. Spaceキー2回でリアルタイム全文検索 (live_grep) ★ここを書き換え
      vim.keymap.set('n', '<Space><Space>', require('telescope.builtin').live_grep, { desc = 'Telescope live grep' })
    end -- config の function を閉じる
  }, -- プラグインのテーブルを閉じる
{
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- アイコン表示用
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
          sources = {
          "filesystem",
          "buffers",
          "git_status",
          "document_symbols", -- これを追加することで初期化エラーが消えます
        },
        window = {
          width = 30, -- ツリーの幅
        },
        filesystem = {
          filtered_items = {
            visible = true, -- .gitignore 以外の隠しファイル（.envなど）を表示
            hide_dotfiles = false,
            hide_gitignored = true, -- gitignore対象（obj や bin）は非表示にする
          }
        }
      })

      -- Ctrl + n でツリーを開閉するキーマップ
      -- vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true })
      -- Ctrl + n で「移動」と「閉じる」を賢く自動切り替えする
-- 💡 先ほどの Lua API を使った確実なキーマップ
      vim.keymap.set('n', '<C-s>', function()
        require('neo-tree.command').execute({
          action = "focus",
          source = "document_symbols",
        })
      end, { silent = true, desc = "Focus Neo-tree Symbols" })

      vim.keymap.set('n', '<C-n>', function()
        -- 現在のバッファのFileTypeを取得
        local current_ft = vim.bo.filetype
        
        if current_ft == "neo-tree" then
          -- すでにツリー上にいるなら、ツリーを閉じる
          vim.cmd("Neotree close")
        else
          -- コード編集画面などにいるなら、ツリーに一発ジャンプ（開いてなければ開く）
          vim.cmd("Neotree focus")
        end
      end, { silent = true, desc = "Toggle or Focus Neo-tree" })
    end
  },
{
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 15, -- ターミナルの高さ
        open_mapping = [[<C-t>]], -- Ctrl + t でターミナルを開閉
        direction = 'horizontal', -- 画面下に水平に開く
        shell = vim.o.shell, -- OS標準のシェル（WindowsならPowerShell等）を使用
      })

      -- ターミナルモードからノーマルモードに戻るキーマップ
      -- ターミナル内で `jj` または `Esc` を押すと操作できるようになります
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', 'jj', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
      end

      -- ターミナルが開いた時だけ上記キーマップを有効にする
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
    end
  },
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
{
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or {}
      -- Roslyn対応の非公式レジストリを登録
      table.insert(opts.registries, "github:Crashdummyy/mason-registry")
    end,
  },
  -- 3. nvim-dap 本体と UI、キーマップの設定 (変更なし)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()

      -- デバッグ開始・終了時にUIを自動で開閉
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- C#用の設定 (自動インストールされた netcoredbg を参照)
      dap.adapters.coreclr = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
        args = { "--interpreter=vscodesm" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "launch - netcoredbg",
          request = "launch",
          program = function()
            -- C#の実行用DLLを選択するプロンプト
            return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
        },
      }

      -- キーマッピングの設定
      vim.keymap.set("n", "<F9>", function() dap.toggle_breakpoint() end, { desc = "DAP: Toggle Breakpoint" })
      vim.keymap.set("n", "<F5>", function() dap.continue() end, { desc = "DAP: Continue" })
      vim.keymap.set("n", "<F10>", function() dap.step_over() end, { desc = "DAP: Step Over" })
      vim.keymap.set("n", "<F11>", function() dap.step_into() end, { desc = "DAP: Step Into" })
      vim.keymap.set("n", "<S-F11>", function() dap.step_out() end, { desc = "DAP: Step Out" })
      vim.keymap.set("n", "<F12>", function() dap.terminate() end, { desc = "DAP: Terminate" })
    end,
  },
{
    "seblyng/roslyn.nvim",
    ft = "cs",
    dependencies = {
      -- 補完プラグイン (nvim-cmp) と LSP の能力を共有するための連携用
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      require("roslyn").setup({
        -- nvim-lspconfig と同様の設定を渡せます
        config = {
          capabilities = capabilities,
          -- 必要に応じて、キーマップなどを割り当てる on_attach を設定
          on_attach = function(client, bufnr)
            -- 例: 定義ジャンプやホバーなどの設定
            local opts = { buffer = bufnr }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          end,
          -- C#の詳細な言語サーバー設定
          settings = {
            ["csharp|background_analysis"] = {
              -- 大規模プロジェクトで重くなるのを防ぐため、開いているファイルのみ解析
              dotnet_analyzer_diagnostics_scope = "openFiles",
              dotnet_compiler_diagnostics_scope = "fullSolution",
            },
          },
        },
        -- 必要に応じてファイルを自動監視する設定
        filewatching = true,
      })
    end,
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
    {
    "keaising/im-select.nvim",
    init = function()
      if vim.env.DISPLAY then
        require("im_select").setup()
        if vim.fn.has("wsl") or vim.fn.has("win32") then
          vim.api.nvim_create_autocmd("VimLeave", {
            callback = function()
              vim.fn.system("im-select.exe 1041")
            end,
          })
          vim.api.nvim_create_autocmd("FocusLost", {
            callback = function()
              vim.fn.system("im-select.exe 1041")
            end,
          })
        end
      end
    end,
  },
})

-- autoread用の状態や、ファイルの変更検知を補助する関数
local function get_file_status()
  if vim.bo.modified then
    return "[+] Modified" -- 編集あり
  elseif vim.bo.readonly then
    return "[-] ReadOnly" -- 読み込み専用
  else
    return "[ ] Clean"    -- 変更なし
  end
end

-- 1. ファイルを読み込んだ（開いた）ときに時刻を記録する関数
local function set_buffer_opened_time()
  -- 現在の時刻を「yyyy/MM/dd hh:mm:ss」の形式でバッファ固有の変数に保存
  vim.b.opened_time = os.date("%Y/%m/%d %H:%M:%S")
end

-- 2. 自動コマンド（Autocmd）でファイル読込時に上記関数を実行
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*",
  callback = set_buffer_opened_time,
})

-- 3. ステータスラインの構成
function MyStatusLine()
  local status = {}

  -- 1. ファイルパス (%f: 相対パス, %F: 絶対パス)
  table.insert(status, " %f ")

  -- 2. ファイルの状態（変更あり/読み込み専用/Clean）
  table.insert(status, get_file_status())

  -- 右寄せにするための区切り
  table.insert(status, "%=")

  -- ★追加: 読み込み時刻の表示
  -- バッファ変数に時刻があれば「読込: yyyy/MM/dd hh:mm:ss」を表示する
  if vim.b.opened_time then
    table.insert(status, " 読込: " .. vim.b.opened_time .. " ")
  end

  -- 3. 文字コード
  local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  table.insert(status, string.upper(encoding) .. " ")

  -- 4. 改行コード (LF / CRLF / CR)
  local ff = vim.bo.fileformat
  table.insert(status, "[" .. string.upper(ff) .. "] ")

  -- 5. カーソル位置 (行:列)
  table.insert(status, " %l:%c %P ")

  return table.concat(status, " │ ")
end

-- ステータスラインを適用
vim.opt.laststatus = 2 -- ステータスラインを常に表示
vim.opt.statusline = "%!v:lua.MyStatusLine()"

-- 1秒（1000ミリ秒）ごとにバックグラウンドで自動チェックするタイマーを作動
local timer = vim.loop.new_timer()
timer:start(0, 1000, vim.schedule_wrap(function()
  -- コマンドライン入力中や、ノーマルモード以外、または未保存の変更がある場合はスキップ
  if vim.fn.mode() == 'n' and not vim.bo.modified then
    vim.cmd('checktime')
  end
end))

-- ファイルが更新されたら、その瞬間に画面を強制再描画する
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  callback = function()
    vim.cmd('redraw')
  end,
})


vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.ps1",
  callback = function()
    vim.opt_local.fileencoding = "utf-8"
    vim.opt_local.bomb = true
  end,
})

-- =====================================================================
-- ★ init.lua の一番最後に貼り付けてください
-- Neovim起動完了後、安全にレジストリを更新してからインストールを実行します
-- =====================================================================
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone", -- lazy.nvimによるプラグインの読み込みがすべて完了した後に実行
  callback = function()
    -- 1秒待ってから、安全にMasonの処理を開始する
    vim.defer_fn(function()
      local registry = require("mason-registry")

      -- レジストリをリフレッシュ（非公式レジストリを確実に読み込ませる）
      registry.refresh(function()
        local packages = { "roslyn", "netcoredbg" }

        for _, pkg_name in ipairs(packages) do
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if ok and not pkg:is_installed() then
            -- インストールされていない場合のみ自動でインストールを開始
            vim.notify("[Mason-Auto] Installing " .. pkg_name .. "...", vim.log.levels.INFO)
            pkg:install()
          end
        end
      end)
    end, 1000)
  end,
})
