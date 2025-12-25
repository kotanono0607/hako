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
# 関数: Desktop Mascotアプリを起動
# ==========================================
function Start-DesktopMascot {
    Set-Location $repoPath

    # 既存のアプリプロセスを終了（もし実行中なら）
    $existingProcess = Get-Process -Name "Desktop Mascot" -ErrorAction SilentlyContinue
    if ($existingProcess) {
        Write-Host "[$(Get-Timestamp)] 既存のアプリを終了しています..." -ForegroundColor Yellow
        $existingProcess | Stop-Process -Force
        Start-Sleep -Seconds 1
    }

    # ビルド済み実行ファイルのパス
    $exePath = "$repoPath\src-tauri\target\release\Desktop Mascot.exe"
    $devExePath = "$repoPath\src-tauri\target\debug\Desktop Mascot.exe"

    if (Test-Path $exePath) {
        # リリースビルドがあれば起動
        Write-Host "[$(Get-Timestamp)] Desktop Mascot を起動しています (Release)..." -ForegroundColor Yellow
        Start-Process -FilePath $exePath -WorkingDirectory $repoPath
    }
    elseif (Test-Path $devExePath) {
        # デバッグビルドがあれば起動
        Write-Host "[$(Get-Timestamp)] Desktop Mascot を起動しています (Debug)..." -ForegroundColor Yellow
        Start-Process -FilePath $devExePath -WorkingDirectory $repoPath
    }
    else {
        # ビルドされていない場合は開発サーバーを起動
        Write-Host "[$(Get-Timestamp)] ビルド済み実行ファイルがないため、開発モードで起動します..." -ForegroundColor Yellow
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d $repoPath && npm run tauri dev" -WorkingDirectory $repoPath
    }
}

# ==========================================
# 関数: アクションを実行
# ==========================================
function Execute-Action {
    Write-Host "[$(Get-Timestamp)] 更新を検知！アクションを実行します。" -ForegroundColor Green

    # 1. Desktop Mascotアプリを起動
    Start-DesktopMascot

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
