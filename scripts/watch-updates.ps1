# ==========================================
# Desktop Mascot - 自動更新監視スクリプト
# ==========================================

# ==========================================
# 設定: ファイルとフォルダの場所
# ==========================================
$desktop = [Environment]::GetFolderPath("Desktop")
$triggerFile = "$desktop\update_signal.txt"
$repoPath = "C:\hako"

# 音声ファイルの場所
$soundFolder = "C:\Users\hello\Documents\Sounds"
$successSound = "$soundFolder\success.wav"
# $errorSound   = "$soundFolder\error.wav"

# ★起動したいアプリ（バッチファイル）の場所
$appPath = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell\実行_pode版.bat"
$appWorkDir = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell"

# チェック間隔（秒）
$checkInterval = 60

# ==========================================
# 関数: 現在日時を取得
# ==========================================
function Get-Timestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# ==========================================
# 関数: WAVファイルを再生する
# ==========================================
function Play-Sound($filePath) {
    if (Test-Path $filePath) {
        $player = New-Object System.Media.SoundPlayer $filePath
        $player.PlaySync() # 再生が終わるまで待つ
        $player.Dispose()
    }
}

# ==========================================
# 関数: Git更新をチェック
# ==========================================
function Check-GitUpdate {
    Set-Location $repoPath

    # 現在のコミットハッシュ
    $localCommit = git rev-parse HEAD 2>$null

    # リモートの変更を取得
    git fetch origin main --quiet 2>$null

    # リモートのmainの最新コミット
    $remoteCommit = git rev-parse origin/main 2>$null

    if ($remoteCommit -and $remoteCommit -ne $localCommit) {
        return @{
            HasUpdate = $true
            LocalCommit = $localCommit
            RemoteCommit = $remoteCommit
        }
    }

    return @{ HasUpdate = $false }
}

# ==========================================
# 関数: 更新を適用
# ==========================================
function Apply-Update($updateInfo) {
    Set-Location $repoPath

    # mainブランチに切り替えてpull
    git checkout main --quiet 2>$null
    git pull origin main --quiet 2>$null

    # トリガーファイルを作成
    $content = @"
Desktop Mascot Update Detected
Time: $(Get-Timestamp)
Commit: $($updateInfo.RemoteCommit)
Previous: $($updateInfo.LocalCommit)
"@
    $content | Out-File -FilePath $triggerFile -Encoding UTF8
}

# ==========================================
# 関数: アクションを実行
# ==========================================
function Execute-Action {
    Write-Host "[$(Get-Timestamp)] 更新を検知！アクションを実行します。" -ForegroundColor Green

    # 1. アプリ（Pode版）を起動
    if (Test-Path $appPath) {
        Write-Host "[$(Get-Timestamp)] アプリを起動しています..." -ForegroundColor Yellow
        Start-Process -FilePath $appPath -WorkingDirectory $appWorkDir
    } else {
        Write-Warning "[$(Get-Timestamp)] アプリが見つかりません: $appPath"
    }

    # 2. 少しだけ間を作る（0.5秒）
    Start-Sleep -Milliseconds 500

    # 3. 成功ボイスを再生
    Play-Sound $successSound

    Write-Host "[$(Get-Timestamp)] アクション完了！" -ForegroundColor Cyan
}

# ==========================================
# メイン処理: 監視ループ
# ==========================================
Write-Host "=========================================="
Write-Host " Desktop Mascot 更新監視"
Write-Host "=========================================="
Write-Host "[$(Get-Timestamp)] 監視を開始しました..."
Write-Host "リポジトリ: $repoPath"
Write-Host "トリガーファイル: $triggerFile"
Write-Host "チェック間隔: ${checkInterval}秒"
Write-Host ""

while ($true) {
    try {
        # Git更新をチェック
        $updateInfo = Check-GitUpdate

        if ($updateInfo.HasUpdate) {
            Write-Host "[$(Get-Timestamp)] 新しい更新を検出しました!" -ForegroundColor Green
            Write-Host "  前回: $($updateInfo.LocalCommit.Substring(0,7))" -ForegroundColor Gray
            Write-Host "  最新: $($updateInfo.RemoteCommit.Substring(0,7))" -ForegroundColor Gray

            # 更新を適用
            Apply-Update $updateInfo
            Write-Host "[$(Get-Timestamp)] トリガーファイルを作成しました: $triggerFile"

            # アクションを実行
            Execute-Action
        }
        else {
            Write-Host "[$(Get-Timestamp)] 更新なし" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[$(Get-Timestamp)] エラー: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds $checkInterval
}
