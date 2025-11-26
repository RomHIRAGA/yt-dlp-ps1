Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# -----------------------------------
# スクリプトディレクトリを安全に取得
# -----------------------------------
if ($PSScriptRoot -and $PSScriptRoot.Trim() -ne "") {
    $scriptDir = $PSScriptRoot
}
elseif ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $scriptDir = Get-Location
}

# XAML 読み込み
$xamlPath = Join-Path $scriptDir "Xaml/gui.xaml"
[xml]$xaml = Get-Content $xamlPath -Raw -Encoding UTF8

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# XAML 内の要素を取得
$UrlBox        = $window.FindName("UrlBox")
$ResolutionBox = $window.FindName("ResolutionBox")
$LogBox        = $window.FindName("LogBox")
$DownloadButton= $window.FindName("DownloadButton")
$ProgressBar   = $window.FindName("ProgressBar")
$FolderButton  = $window.FindName("FolderButton")

# 保存フォルダ（初期値：スクリプトと同じ場所）
$global:SaveFolder = $scriptDir

# -----------------------------------
# ログ出力
# -----------------------------------
function Write-Log($msg) {
    $LogBox.AppendText("$msg`r`n")
    $LogBox.ScrollToEnd()
}

# -----------------------------------
# 保存フォルダ選択
# -----------------------------------
$FolderButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $global:SaveFolder = $dialog.SelectedPath
        Write-Log "保存フォルダ: $global:SaveFolder"
    }
})

# -----------------------------------
# Download ボタン
# -----------------------------------
$DownloadButton.Add_Click({
    $url = $UrlBox.Text.Trim()
    if ($url -eq "") {
        Write-Log "URLが空です"
        return
    }

    # 解像度フォーマットID取得
    $selectedItem = $ResolutionBox.SelectedItem
    $formatID = $selectedItem.Tag

    $yt = Join-Path $scriptDir "yt-dlp.exe"
    $cookies = Join-Path $scriptDir "cookies.txt"

    if (-not (Test-Path $yt)) {
        Write-Log "yt-dlp.exe が見つかりません"
        return
    }
    if (-not (Test-Path $cookies)) {
        Write-Log "cookies.txt が見つかりません"
        return
    }

    Write-Log "ダウンロード開始..."
    $ProgressBar.Value = 10

    $argList = "--cookies `"$cookies`" --extractor-args `"youtube:player_skip=tv_html5,web_embedded,android`" --extractor-args `"youtube:player_client=web_safari;generate_sapisidhash=1`" -f $formatID -o `"$global:SaveFolder/%(title)s.%(ext)s`" `"$url`""

    Write-Log "実行中..."
    $ProgressBar.Value = 40

    $process = Start-Process -FilePath $yt -ArgumentList $argList -RedirectStandardOutput "$scriptDir\yt_log.txt" -NoNewWindow -PassThru
    $process.WaitForExit()

    $ProgressBar.Value = 80

    if (Test-Path "$scriptDir\yt_log.txt") {
        Write-Log (Get-Content "$scriptDir\yt_log.txt" -Raw)
    }

    $ProgressBar.Value = 100
    Write-Log "完了！"
})

# -----------------------------------
# クリップボード監視： URLなら自動入力
# -----------------------------------
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
    $clip = [Windows.Forms.Clipboard]::GetText()
    if ($clip -match "^https://www\.youtube\.com/watch") {
        $UrlBox.Text = $clip
    }
})
$timer.Start()

# -----------------------------------
# GUI表示
# -----------------------------------
$window.ShowDialog() | Out-Null
