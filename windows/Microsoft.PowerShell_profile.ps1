Set-PSReadlineOption -EditMode vi
Set-PSReadlineOption -HistorySearchCursorMovesToEnd

Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Chord Ctrl+e -Function EndOfLine
Set-PSReadLineKeyHandler -Chord Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Chord Ctrl+f -Function NextWord
Set-PSReadLineKeyHandler -Chord Ctrl+b -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Alt+. -Function YankLastArg

# F2で有効になるやつ
# https://qiita.com/minarin0179/items/0a17a576f642bab56762
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

function Open-GitBash{ cmd /c 'start "" "%PROGRAMFILES%\Git\bin\bash.exe" --login' }
function Open-SourceDir { cd "C:\workspace"}
function Open-DownloadDir {cd  ${env:USERPROFILE}\Downloads}
function Open-VpRelease { cd ${env:USERPROFILE}\Documents\02_visionpose_release\VisionPose_v1.6.3_win_cpp\tools }
function Open-Aipo { start https://next-system.ddo.jp/aipo/ }
function Open-Knowledge { 
    if ($args.Count -gt 0) {
        $searchword = $args -join "+"
        $url = "http://knowledge.next-system.ddo.jp/open.knowledge/list?keyword=" + $searchword
        start $url
    }
    else {
       start http://knowledge.next-system.ddo.jp/
    }
}
function Open-SpreadSheet { start https://docs.google.com/spreadsheets/u/0/?tgif=d }
function Open-Gitbucket { start http://prime.next-system.ddo.jp:8081/ }
function Open-Twitter { start https://twitter.com/next_kinesys }
function Open-GoogleNews { start "https://news.google.com/topstories?hl=ja&gl=JP&ceid=JP:ja" }
function Open-GoogleSearch {
    $searchword = $args -join "+"
    $url = "https://www.google.com/search?hl=ja&source=hp&q=" + $searchword
    start $url
}

function Cmd-Start {
    cmd /c start $args
}

function Convert-Avi2mp4 {
   Param(
      $Dir = "."
   )
   $files = Get-ChildItem -r -Filter "*.avi" $Dir
   foreach($file in $files) {
       $out = $file.FullName.split('.')[0] + ".mp4"
       if (Test-Path $out) {
           echo "skip file $out"
           continue
       }
       ffmpeg -i "$file" $out
   }

}

# https://qiita.com/tsukamoto/items/917cd3ec84f789088d7c
function Gen-Password {
    Param(
        $Len = 32,
        $MinChar = 3
    )
    $length = $Len

    $letters = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
    $uppers = "ABCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
    $lowers = "abcdefghijkmnopqrstuvwxyz".ToCharArray()
    $digits = "23456789".ToCharArray()
    $symbols = "_-+=@$%".ToCharArray()

    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789_-+=@$%".ToCharArray()

    do {
        $pwdChars = "".ToCharArray()
        $goodPassword = $false
        $hasDigit = $false
        $hasSymbol = $false
        $pwdChars += (Get-Random -InputObject $uppers -Count 1)
        for ($i=1; $i -lt ($length - 1); $i++) {
            $char = Get-Random -InputObject $chars -Count 1
            if ($digits -contains $char) { $hasDigit = $true }
            if ($symbols -contains $char) { $hasSymbol = $true }
            $pwdChars += $char
        }
        $pwdChars += (Get-Random -InputObject $lowers -Count 1)
        $password = $pwdChars -join ""
        $goodPassword = $hasDigit -and $hasSymbol
    } until ($goodPassword)
    
    Write-Output $password
    Set-Clipboard $password

    # ホームディレクトリ直下のpassword_log.txtファイルに追記
    $homeDir = [System.Environment]::GetFolderPath('MyDocuments')  # Homeディレクトリのパスを取得
    $filePath = Join-Path -Path $homeDir -ChildPath "password_log.txt"  # ファイルパスを作成
    $timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    "$timestamp $password" | Out-File -Append -FilePath $filePath
}

function CondaActivate {
    conda activate $(Get-ChildItem C:\Users\next\scoop\apps\miniconda3\current\envs -directory -name | fzf --height=10% --reverse --border)
}

# Alias
del alias:ls  # PowerShell 側の ls を削除
function ls() {
    ls.exe --color=auto $args
}
function ll() {
    ls.exe --color=auto -l $args
}
function la() {
    ls.exe --color=auto -la $args
}

# 縦に並べる (Vertical Stack)
function mpv-vstack {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$file1,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$file2
    )

    mpv "$file1" --external-file="$file2" --lavfi-complex="[vid1][vid2]vstack[vo]"
}

# 横に並べる (Horizontal Stack)
function mpv-hstack {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$file1,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$file2
    )

    mpv "$file1" --external-file="$file2" --lavfi-complex="[vid1][vid2]hstack[vo]"
}

function mpv-quad-diff {
    param(
        [Parameter(Mandatory=$true, Position=0)] [string]$file1,
        [Parameter(Mandatory=$true, Position=1)] [string]$file2
    )

    $txt1 = "Original"
    $txt2 = "Comparison"
    $txt3 = "Overlay"
    $txt4 = "Difference"

    $fSize = 36
    $fColor = "yellow"
    $fBox = 1
    $fBoxCol = "black@0.5"

    $font = "'C\:/Windows/Fonts/meiryo.ttc'"

    function Escape-DrawText($text) {
        return ($text -replace '%', '%%') -replace ':', '\:'
    }

    function Draw($label, $text, $out) {
        $t = Escape-DrawText $text
        return "[$label]drawtext=fontfile=$font`:text='$t'`:fontcolor=$fColor`:fontsize=$fSize`:box=$fBox`:boxcolor=$fBoxCol`:x=20`:y=20[$out]"
    }

    $filter = @()

    # ★ ここで全部分岐（超重要）
    $filter += "[vid1]format=gbrp,split=3[v1a][v1b][v1c]"
    $filter += "[vid2]format=gbrp,split=3[v2a][v2b][v2c]"

    # それぞれ用途分け
    # v1a/v2a → 表示
    # v1b/v2b → overlay
    # v1c/v2c → difference

    $filter += "[v1b][v2b]blend=all_opacity=0.5[ov]"
    $filter += "[v1c][v2c]blend=all_mode=difference[df]"

    # drawtext（最後）
    $filter += Draw "v1a" $txt1 "t1"
    $filter += Draw "v2a" $txt2 "t2"
    $filter += Draw "ov"  $txt3 "t3"
    $filter += Draw "df"  $txt4 "t4"

    # 合成
    $filter += "[t1][t2][t3][t4]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[vo]"

    $fullFilter = ($filter -join ";")

    & mpv `
        $file1 `
        --external-file=$file2 `
        --lavfi-complex=$fullFilter
}

function Get-VP-Hash {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$Path
    )

    begin {
        # 1. beginの中で、渡された全てのパスからファイル一覧を確定させる
        # ※この時点で $fileList に全てのファイルが保持される
        $fileList = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
    }

    process {
        # 2. processが呼ばれたときには、すでに $fileList がある状態
        # ここではリストを回して計算を行う
        foreach ($file in $fileList) {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            
            [PSCustomObject]@{
                Name   = $file.Name
                Length = $file.Length
                MiB    = [Math]::Truncate($file.Length / 1MB)
                Hash   = $hash.Hash
            }
        }
    }
}


#Replace default powershell prompt
$_prompt = (Get-Command Prompt).scriptblock
# https://stackoverflow.com/questions/42187967/reverting-to-the-original-prompt-in-powershell-console
function prompt
{
    $ret = Invoke-Command -ScriptBlock $_prompt
    Write-Prompt $ret
    $prompt = & $GitPromptScriptBlock
    Write-Prompt $prompt
    Write-Prompt "test"
    return "$ "
}

function git-open { cmd /c "C:\Program Files\Git\usr\bin\bash.exe" "git open" }
Set-Alias -Name gop -Value git-open

sal git-bash Open-GitBash
sal src Open-SourceDir
sal vp Open-VpRelease
sal aipo Open-Aipo
sal knwledge Open-Knowledge
sal spreadsheet Open-SpreadSheet
sal gitbucket Open-Gitbucket
sal twitter Open-Twitter
sal news Open-GoogleNews
sal google Open-GoogleSearch
sal password Gen-Password
sal ca CondaActivate
sal d Open-DownloadDir
sal convertavi2mp4 Convert-Avi2mp4
del alias:start -Force
sal start Cmd-Start

function GnuWhich($command) { (Get-Command $command).Definition}

sal which GnuWhich

function CustomListChildItems { Get-ChildItem $args[0] -force | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, @{ Expression = 'Name'; Ascending = $true } | Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name }
sal ll CustomListChildItems

function CustomSudo {Start-Process powershell.exe -Verb runas}
sal sudo CustomSudo

function CustomHosts {start notepad C:\Windows\System32\drivers\etc\hosts -verb runas}
sal hosts CustomHosts

function CustomUpdate {explorer ms-settings:windowsupdate}
sal update CustomUpdate

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

Import-Module posh-git
$GitPromptSettings.DefaultPromptWriteStatusFirst = $true
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n$([DateTime]::now.ToString("MM-dd HH:mm:ss"))'
$GitPromptSettings.DefaultPromptBeforeSuffix.ForegroundColor = 0x808080
$GitPromptSettings.DefaultPromptSuffix = ' $((Get-History -Count 1).id + 1)$(">" * ($nestedPromptLevel + 1)) '

. $PSScriptRoot/ssh-completion.ps1

# https://blog.mamansoft.net/2020/05/31/windows-terminal-and-power-shell-makes-beautiful/#%E6%96%87%E5%AD%97%E5%8C%96%E3%81%91%E3%82%92%E8%A7%A3%E6%B6%88%E3%81%99%E3%82%8B

# PowerShell Core7でもConsoleのデフォルトエンコーディングはsjisなので必要
[System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")
[System.Console]::InputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# git logなどのマルチバイト文字を表示させるため (絵文字含む)
$env:LESSCHARSET = "utf-8"

# slエイリアスを削除
# https://stackoverflow.com/questions/76179076/how-can-i-remove-a-constant-alias-in-powershell
Remove-Item -Force Alias:sl

Remove-Item -Force Alias:\cat
Remove-Item -Force Alias:\cp
Remove-Item -Force Alias:\mv
Remove-Item -Force Alias:\pwd
Remove-Item -Force Alias:\rm
Remove-Item -Force Alias:\tee


$env:MISE_SHELL = 'pwsh'
if (-not (Test-Path -Path Env:/__MISE_ORIG_PATH)) {
    $env:__MISE_ORIG_PATH = $env:PATH
}

function mise {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]  # Allow any number of arguments, including none
        [string[]] $arguments
    )

    $previous_out_encoding = $OutputEncoding
    $previous_console_out_encoding = [Console]::OutputEncoding
    $OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

    function _reset_output_encoding {
        $OutputEncoding = $previous_out_encoding
        [Console]::OutputEncoding = $previous_console_out_encoding
    }

    if ($arguments.count -eq 0) {
        & "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe"
        _reset_output_encoding
        return
    } elseif ($arguments -contains '-h' -or $arguments -contains '--help') {
        & "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe" @arguments
        _reset_output_encoding
        return
    }

    $command = $arguments[0]
    if ($arguments.Length -gt 1) {
        $remainingArgs = $arguments[1..($arguments.Length - 1)]
    } else {
        $remainingArgs = @()
    }

    switch ($command) {
        { $_ -in 'deactivate', 'shell', 'sh' } {
            & "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe" $command @remainingArgs | Out-String | Invoke-Expression -ErrorAction SilentlyContinue
            _reset_output_encoding
        }
        default {
            & "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe" $command @remainingArgs
            $status = $LASTEXITCODE
            if ($(Test-Path -Path Function:\_mise_hook)){
                _mise_hook
            }
            _reset_output_encoding
            # Pass down exit code from mise after _mise_hook
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                pwsh -NoProfile -Command exit $status
            } else {
                powershell -NoProfile -Command exit $status
            }
        }
    }
}

function Global:_mise_hook {
    if ($env:MISE_SHELL -eq "pwsh"){
        $output = & "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe" hook-env $args -s pwsh | Out-String
        if ($output -and $output.Trim()) {
            $output | Invoke-Expression
        }
    }
}

function __enable_mise_chpwd{
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        if ($env:MISE_PWSH_CHPWD_WARNING -ne '0') {
            Write-Warning "mise: chpwd functionality requires PowerShell version 7 or higher. Your current version is $($PSVersionTable.PSVersion). You can add `$env:MISE_PWSH_CHPWD_WARNING=0` to your environment to disable this warning."
        }
        return
    }
    if (-not $__mise_pwsh_chpwd){
        $Global:__mise_pwsh_chpwd= $true
        $_mise_chpwd_hook = [EventHandler[System.Management.Automation.LocationChangedEventArgs]] {
            param([object] $source, [System.Management.Automation.LocationChangedEventArgs] $eventArgs)
            end {
                _mise_hook
            }
        };
        $__mise_pwsh_previous_chpwd_function=$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction;

        if ($__mise_original_pwsh_chpwd_function) {
            $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = [Delegate]::Combine($__mise_pwsh_previous_chpwd_function, $_mise_chpwd_hook)
        }
        else {
            $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = $_mise_chpwd_hook
        }
    }
}
__enable_mise_chpwd
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_chpwd

function __enable_mise_prompt {
    if (-not $__mise_pwsh_previous_prompt_function){
        $Global:__mise_pwsh_previous_prompt_function=$function:prompt
        function global:prompt {
            if (Test-Path -Path Function:\_mise_hook){
                _mise_hook
            }
            & $__mise_pwsh_previous_prompt_function
        }
    }
}
__enable_mise_prompt
Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_prompt

_mise_hook
if (-not $__mise_pwsh_command_not_found){
    $Global:__mise_pwsh_command_not_found= $true
    function __enable_mise_command_not_found {
        $_mise_pwsh_cmd_not_found_hook = [EventHandler[System.Management.Automation.CommandLookupEventArgs]] {
            param([object] $Name, [System.Management.Automation.CommandLookupEventArgs] $eventArgs)
            end {
                if ([Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()[-1].CommandLine -match ([regex]::Escape($Name))) {
                    if (& "C:\Users\next\AppData\Local\Microsoft\WinGet\Links\mise.exe" hook-not-found -s pwsh -- $Name){
                        _mise_hook
                        if (Get-Command $Name -ErrorAction SilentlyContinue){
                            $EventArgs.Command = Get-Command $Name
                            $EventArgs.StopSearch = $true
                        }
                    }
                }
            }
        }
        $current_command_not_found_function = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
        if ($current_command_not_found_function) {
            $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = [Delegate]::Combine($current_command_not_found_function, $_mise_pwsh_cmd_not_found_hook)
        }
        else {
            $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $_mise_pwsh_cmd_not_found_hook
        }
    }
    __enable_mise_command_not_found
    Remove-Item -ErrorAction SilentlyContinue -Path Function:/__enable_mise_command_not_found
}

$wt_completer = {
    param($wordToComplete, $commandAst, $cursorPosition)

    # settings.json のパス（環境に合わせて自動切り替え）
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $settingsPath)) {
        $settingsPath = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    }

    if (Test-Path $settingsPath) {
        # Tabを押した瞬間にファイルを読み込むので、設定変更も即反映
        try {
            $json = Get-Content $settingsPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
            $profiles = $json.profiles.list.name
            
            # 入力中の文字に前方一致するプロファイル名を返す
            $profiles | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                # スペースを含むプロファイル名に対応するため、引用符で囲む
                $completionText = if ($_ -match ' ') { "`"$_`"" } else { $_ }
                [System.Management.Automation.CompletionResult]::new($completionText, $_, 'ParameterValue', $_)
            }
        } catch {
            # JSONが壊れている場合などは何もしない
        }
    }
}

function Send-WOL {
    param(
        [Parameter(Mandatory=$true)]
        [string]$MacAddress
    )

    try {
        # MACアドレスの整形（ハイフンやコロンを除去）
        $cleanMac = $MacAddress.Replace("-","").Replace(":","")
        $target = [Net.NetworkInformation.PhysicalAddress]::Parse($cleanMac)
        
        # マジックパケットの生成 (FF*6 + MAC*16)
        $packet = [Byte[]](,0xFF * 6) + ($target.GetAddressBytes() * 16)

        # 送信処理
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect([System.Net.IPAddress]::Broadcast, 9)
        $udpClient.Send($packet, $packet.Length) > $null
        $udpClient.Close()

        Write-Host "Success: WOL packet sent to $MacAddress" -ForegroundColor Green
    }
    catch {
        Write-Error "Error: MACアドレスの形式が正しくありません。 ($MacAddress)"
    }
}

# 短いエイリアス（別名）を設定
Set-Alias wol Send-WOL

# -ParameterName を抜いて、コマンド名に対して登録
Register-ArgumentCompleter -Native -CommandName wt -ScriptBlock $wt_completer


function Get-DomainCertStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$Domains
    )

    process {
        foreach ($domain in $Domains) {
            # 入力値の整形（空白削除、プロトコル除去）
            $target = $domain.Trim() -replace "^https?://", "" -replace "/.*$", ""
            if (-not $target) { continue }

            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $sslStream = $null

            try {
                # 接続試行
                $connect = $tcpClient.BeginConnect($target, 443, $null, $null)
                if (-not $connect.AsyncWaitHandle.WaitOne(5000, $false)) { throw "Timeout" }
                $tcpClient.EndConnect($connect)

                # SSLハンドシェイク（証明書検証はスルーして中身だけ取る）
                $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { $true })
                $sslStream.AuthenticateAsClient($target)

                # 証明書オブジェクトを取得
                $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$sslStream.RemoteCertificate

                if ($cert) {
                    # 1件ずつオブジェクトを生成して出力（メモリに溜めない）
                    [PSCustomObject]@{
                        Domain      = $target
                        Status      = "OK"
                        Created     = $cert.NotBefore # 作成日（発行日）
                        Expiration  = $cert.NotAfter  # 有効期限
                        DaysLeft    = ($cert.NotAfter - (Get-Date)).Days
                        Issuer      = ($cert.Issuer -split ",")[0]
                    }
                }
            }
            catch {
                [PSCustomObject]@{
                    Domain      = $target
                    Status      = "Error: $($_.Exception.Message)"
                    Created     = $null
                    Expiration  = $null
                    DaysLeft    = $null
                    Issuer      = $null
                }
            }
            finally {
                # リソース解放
                if ($sslStream) { $sslStream.Dispose() }
                if ($tcpClient) { $tcpClient.Dispose() }
            }
        }
    }
}

Set-Alias -Name vim -Value nvim -Force

# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Inlining the template into the profile shaves off ~10ms (25%).
$script:__COREUTILS__ = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('arch','b2sum','base32','base64','basename','basenc','cat','cksum','comm','cp','csplit','cut','date','df','dirname','du','echo','env','expr','factor','false','find','fmt','fold','grep','head','hostname','join','la','link','ln','ls','md5sum','mkdir','mktemp','mv','nl','nproc','numfmt','od','paste','pathchk','pr','printenv','printf','ptx','pwd','readlink','realpath','rm','rmdir','seq','sha1sum','sha224sum','sha256sum','sha384sum','sha512sum','shuf','sleep','sort','split','stat','sum','tac','tail','tee','test','touch','tr','true','truncate','tsort','unexpand','uniq','unlink','uptime','wc','xargs','yes'),
    [System.StringComparer]::OrdinalIgnoreCase
)

$script:__COREUTILS_FAST_SKIP__ = [regex]::new(
    '\b(?:' + ($script:__COREUTILS__ -join '|') + ')\b',
    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

# Casting the scriptblock to Func<Ast,bool> once and reusing it avoids the
# per-FindAll scriptblock-to-delegate wrapping overhead (~1.7x faster).
$script:__COREUTILS_CMD_PREDICATE__ = [System.Func[System.Management.Automation.Language.Ast, bool]] {
    param($n) $n -is [System.Management.Automation.Language.CommandAst]
}

$script:__COREUTILS_ARG_SPECIAL__ = [char[]] @("'", '"', '`', '$')

# Wrap arguments into quotes. By being a function we can properly handle $variables.
# As per MSVCRT, any `\` before `"` must be doubled to escape them.
function global:__coreutils_q {
    param($s)
    '"' + (([string]$s) -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

# PowerShell tokenizes `*"a"*` as [BareWord] instead of the expected [DoubleQuoted, BareWord, DoubleQuoted].
# To work around that we use... regex. Group 1 = 'single', 2 = "double", 3 = `escape, 4 = bare run.
$script:__COREUTILS_ARG_RX__ = [regex]::new(
    "'((?:[^']|'')*)'|""((?:[^""``]|""""|``.)*)""|``(.)|([^'""``]+)",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:__COREUTILS_ARG_EVAL__ = [System.Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($m.Groups[1].Success) {
        # Single-quoted: literal. PS '' -> ', then MSVCRT-quote.
        $body = $m.Groups[1].Value.Replace("''", "'")
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[2].Success) {
        # Double-quoted: collapse PS quote-escapes to raw " / ', let ExpandString
        # resolve `n / `t / $var, then MSVCRT-quote.
        $body = $m.Groups[2].Value.
        Replace('`"', '"').
        Replace("``'", "'").
        Replace('""', '"')
        $body = $ExecutionContext.InvokeCommand.ExpandString($body)
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[3].Success) {
        # Backtick-escaped char outside a string: " -> \"; everything else
        # becomes a one-char quoted region so glob metas stay literal.
        $c = $m.Groups[3].Value
        if ($c -eq '"') {
            return '\"'
        }
        return '"' + $c + '"'
    }
    # Bare run: passed through unquoted so coreutils can glob it; expand $vars.
    return $ExecutionContext.InvokeCommand.ExpandString($m.Groups[4].Value)
}

# 0: not tested, 1: coreutils not installed, 2: coreutils installed.
$script:__COREUTILS_CMD_DIR_TEST__ = 0

# PSConsoleHostReadLine override that rewrites coreutils command names to their
# .cmd equivalents after PSReadLine returns (history keeps the original).
#
# Why .cmd over .exe: PSNativeCommandArgumentPassing = 'Windows' results in a behavior
# where passing bare quotes to CreateProcess() is impossible. This prevents us from
# passing "*" as "*" to coreutils and instead will be given as a bare *.
# This causes it to treat it as a glob pattern. "*.cmd" files however are automatically
# treated as PSNativeCommandArgumentPassing = 'Legacy', which preserves quotes.
# It is the only possible workaround and the only way coreutils can work at all.
function PSConsoleHostReadLine {
    [System.Diagnostics.DebuggerHidden()]
    param()

    $lastRunStatus = $?
    Microsoft.PowerShell.Core\Set-StrictMode -Off
    $line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)

    # If the line contains no coreutils name, we don't need to parse the AST at all.
    if (-not $script:__COREUTILS_FAST_SKIP__.IsMatch($line)) {
        return $line
    }

    # Roamed/synced profiles can load this snippet on machines where coreutils is not installed.
    # Test for the existence of the command directory once and remember the result.
    if ($script:__COREUTILS_CMD_DIR_TEST__ -eq 0) {
        $script:__COREUTILS_CMD_DIR_TEST__ = 1
        if (Test-Path -LiteralPath 'C:\Program Files\coreutils\cmd\' -PathType Container -ErrorAction Ignore) {
            $script:__COREUTILS_CMD_DIR_TEST__ = 2
        }
    }
    if ($script:__COREUTILS_CMD_DIR_TEST__ -ne 2) {
        return $line
    }

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$null)
    $commands = $ast.FindAll($script:__COREUTILS_CMD_PREDICATE__, $true)

    # Process right-to-left so earlier offsets stay valid after each splice.
    # In-place reverse beats Sort-Object for the typical 1-command line.
    if ($commands.Count -gt 1) {
        $commands = [System.Collections.Generic.List[object]]::new($commands)
        $commands.Reverse()
    }

    foreach ($cmd in $commands) {
        $name = $cmd.GetCommandName()
        if (!$name) {
            continue
        }

        $baseName = $name
        if ($name.EndsWith('.exe') -or $name.EndsWith('.cmd')) {
            $baseName = $name.Substring(0, $name.Length - 4)
        }
        if (!$script:__COREUTILS__.Contains($baseName)) {
            continue
        }

        # ls/la get colour + listing flags injected; la also rewrites to ls.
        $cmdElement = $cmd.CommandElements[0]
        $start = $cmdElement.Extent.StartOffset
        $end = $cmdElement.Extent.EndOffset
        $replacement = "& 'C:\Program Files\coreutils\cmd\"

        switch ($baseName) {
            'la' { $replacement += "ls.cmd' --color=auto -AFhl" }
            'ls' { $replacement += "ls.cmd' --color=auto" }
            default { $replacement += "$baseName.cmd'" }
        }

        # Walk command elements, merging adjacent ones whose extents touch
        # (e.g. `'a'*` parses as [SingleQuoted, BareWord] but is one shell word).
        # The inverse case `*'a'*` parses as a single BareWord whose text
        # contains the embedded quotes, which is why AST-only analysis
        # isn't enough and we still need to re-tokenize the source span.
        $argsStart = $end
        $argsEnd = $cmd.Extent.EndOffset
        $rewrittenArgs = ''
        $elements = $cmd.CommandElements
        $count = $elements.Count
        $i = 1
        while ($i -lt $count) {
            $first = $elements[$i]
            $wordStart = $first.Extent.StartOffset
            $wordEnd = $first.Extent.EndOffset
            $merged = $false
            while ($i + 1 -lt $count -and $elements[$i + 1].Extent.StartOffset -eq $wordEnd) {
                $i++
                $wordEnd = $elements[$i].Extent.EndOffset
                $merged = $true
            }
            $source = $line.Substring($wordStart, $wordEnd - $wordStart)
            $rewrittenArgs += $line.Substring($argsStart, $wordStart - $argsStart)
            $argsStart = $wordEnd
            # IndexOfAny beats running the regex per arg.
            if ($source.IndexOfAny($script:__COREUTILS_ARG_SPECIAL__) -lt 0) {
                $rewrittenArgs += $source
                $i++
                continue
            }
            # A single un-merged PS expression that needs $var resolution
            # (bare $var, "...$var...", $x.Member, $($expr), etc.).
            # Defer evaluation to runtime so the value reaches coreutils as a literal arg.
            # This matches POSIX behaviour where variable expansions don't result in globbing.
            if (-not $merged -and
                ($first -is [System.Management.Automation.Language.VariableExpressionAst] -or
                $first -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
                $first -is [System.Management.Automation.Language.MemberExpressionAst])) {
                $rewrittenArgs += '(__coreutils_q ' + $source + ')'
                $i++
                continue
            }
            # Slow path: re-tokenise and re-emit as MSVCRT-style quoting,
            # then wrap in PS single quotes so PS hands the body verbatim.
            $windowsQuoted = $script:__COREUTILS_ARG_RX__.Replace($source, $script:__COREUTILS_ARG_EVAL__)
            $rewrittenArgs += "'" + $windowsQuoted.Replace("'", "''") + "'"
            $i++
        }
        $rewrittenArgs += $line.Substring($argsStart, $argsEnd - $argsStart)

        $line = $line.Substring(0, $start) + $replacement + $rewrittenArgs + $line.Substring($argsEnd)
    }

    return $line
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a
