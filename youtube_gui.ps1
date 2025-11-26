# -------------------------
# YouTube Downloader GUI
# UTF-8 BOM で保存必須
# -------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ========== フォーム作成 ==========
$form              = New-Object System.Windows.Forms.Form
$form.Text         = "YouTube Downloader GUI"
$form.Size         = New-Object System.Drawing.Size(600, 300)
$form.StartPosition = "CenterScreen"

# ========== URL 入力 ==========
$labelUrl      = New-Object System.Windows.Forms.Label
$labelUrl.Text = "YouTube URL:"
$labelUrl.Location = New-Object System.Drawing.Point(20, 20)
$labelUrl.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($labelUrl)

$textUrl = New-Object System.Windows.Forms.TextBox
$textUrl.Location = New-Object System.Drawing.Point(20, 45)
$textUrl.Size = New-Object System.Drawing.Size(540, 25)
$form.Controls.Add($textUrl)

# ========== 実行ログ ==========
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 120)
$logBox.Size = New-Object System.Drawing.Size(540, 120)
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$form.Controls.Add($logBox)

# ========== Download ボタン ==========
$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Download"
$btn.Location = New-Object System.Drawing.Point(20, 80)
$btn.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btn)

# ========== ダウンロード処理 ==========
$btn.Add_Click({
    $url = $textUrl.Text.Trim()

    if ($url -eq "") {
        [System.Windows.Forms.MessageBox]::Show("URL を入力してください。")
        return
    }

    $logBox.AppendText("ダウンロード開始…`r`n")

    # yt-dlp のパス（ps1 と同じフォルダにある前提）
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $yt = Join-Path $scriptDir "yt-dlp.exe"
    $cookies = Join-Path $scriptDir "cookies.txt"

    if (-not (Test-Path $yt)) {
        $logBox.AppendText("yt-dlp.exe が見つかりません。`r`n")
        return
    }

    # コマンド作成
    $cmd = "`"$yt`" --cookies `"$cookies`" --extractor-args `"youtube:player_skip=tv_html5,web_embedded,android`" --extractor-args `"youtube:player_client=web_safari;generate_sapisidhash=1`" -o `"%\(title\)s.\%(ext\)s`" `"$url`""

    $logBox.AppendText("実行中…`r`n")

    # yt-dlp 実行
    $process = Start-Process powershell -ArgumentList "-NoProfile -Command $cmd" -RedirectStandardOutput "$scriptDir\yt_log.txt" -NoNewWindow -PassThru
    $process.WaitForExit()

    # ログを表示
    if (Test-Path "$scriptDir\yt_log.txt") {
        $log = Get-Content "$scriptDir\yt_log.txt" -Raw
        $logBox.AppendText($log + "`r`n")
    }

    $logBox.AppendText("完了しました！`r`n")
})

# ========== GUI 起動 ==========
$form.ShowDialog()
