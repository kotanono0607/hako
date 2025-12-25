# ==========================================
# Desktop Mascot - 自動更新監視スクリプト
# 2つの監視を同時に行う:
#   1. Git更新 → Desktop Mascot起動
#   2. トリガーファイル → 実行_pode版.bat起動
# ==========================================

# ==========================================
# 設定: ファイルとフォルダの場所
# ==========================================
$desktop = [Environment]::GetFolderPath("Desktop")
$repoPath = "C:\hako"

# トリガーファイル
$triggerFileMascot = "$desktop\mascot_update_signal.txt"
$triggerFilePode = "$desktop\update_signal.txt"

# 音声ファイルの場所
$soundFolder = "C:\Users\hello\Documents\Sounds"
$successSound = "$soundFolder\success.wav"
# $errorSound   = "$soundFolder\error.wav"

# ★起動したいアプリ（実行_pode版.bat）の場所
$podeAppPath = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell\実行_pode版.bat"
$podeAppWorkDir = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell"

# チェック間隔（秒）
$checkInterval = 1

# Git更新チェック間隔（秒）- 60秒ごとにGit確認
$gitCheckInterval = 60
$lastGitCheck = [DateTime]::MinValue

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
        $player.PlaySync()
        $player.Dispose()
    }
}

# ==========================================
# 関数: Git更新をチェック
# ==========================================
function Check-GitUpdate {
    Set-Location $repoPath

    $localCommit = git rev-parse HEAD 2>$null
    git fetch origin main --quiet 2>$null
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
# 関数: Git更新を適用
# ==========================================
function Apply-GitUpdate($updateInfo) {
    Set-Location $repoPath
    git checkout main --quiet 2>$null
    git pull origin main --quiet 2>$null

    # トリガーファイル（Desktop Mascot用）
    @"
Desktop Mascot Update Detected
Time: $(Get-Timestamp)
Commit: $($updateInfo.RemoteCommit)
Previous: $($updateInfo.LocalCommit)
"@ | Out-File -FilePath $triggerFileMascot -Encoding UTF8
    Write-Host "[$(Get-Timestamp)] トリガーファイル作成: $triggerFileMascot" -ForegroundColor Cyan
}

# ==========================================
# 関数: Desktop Mascotアプリを起動
# ==========================================
function Start-DesktopMascot {
    Set-Location $repoPath

    $existingProcess = Get-Process -Name "Desktop Mascot" -ErrorAction SilentlyContinue
    if ($existingProcess) {
        Write-Host "[$(Get-Timestamp)] 既存のDesktop Mascotを終了..." -ForegroundColor Yellow
        $existingProcess | Stop-Process -Force
        Start-Sleep -Seconds 1
    }

    $exePath = "$repoPath\src-tauri\target\release\Desktop Mascot.exe"
    $devExePath = "$repoPath\src-tauri\target\debug\Desktop Mascot.exe"

    if (Test-Path $exePath) {
        Write-Host "[$(Get-Timestamp)] Desktop Mascot を起動 (Release)..." -ForegroundColor Yellow
        Start-Process -FilePath $exePath -WorkingDirectory $repoPath
    }
    elseif (Test-Path $devExePath) {
        Write-Host "[$(Get-Timestamp)] Desktop Mascot を起動 (Debug)..." -ForegroundColor Yellow
        Start-Process -FilePath $devExePath -WorkingDirectory $repoPath
    }
    else {
        Write-Host "[$(Get-Timestamp)] Desktop Mascot を起動 (開発モード)..." -ForegroundColor Yellow
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d $repoPath && npm run tauri dev" -WorkingDirectory $repoPath
    }
}

# ==========================================
# 関数: Pode版アプリを起動
# ==========================================
function Start-PodeApp {
    if (Test-Path $podeAppPath) {
        Write-Host "[$(Get-Timestamp)] 実行_pode版.bat を起動..." -ForegroundColor Yellow
        Start-Process -FilePath $podeAppPath -WorkingDirectory $podeAppWorkDir
    } else {
        Write-Warning "[$(Get-Timestamp)] アプリが見つかりません: $podeAppPath"
    }
}

# ==========================================
# メイン処理: 監視ループ
# ==========================================
Write-Host "=========================================="
Write-Host " Desktop Mascot 更新監視"
Write-Host "=========================================="
Write-Host "[$(Get-Timestamp)] 監視を開始しました..."
Write-Host "リポジトリ: $repoPath"
Write-Host "トリガーファイル (Mascot): $triggerFileMascot"
Write-Host "トリガーファイル (Pode): $triggerFilePode"
Write-Host "Git更新チェック間隔: ${gitCheckInterval}秒"
Write-Host ""

while ($true) {
    $now = Get-Date

    # ==========================================
    # 1. Git更新チェック（60秒ごと）
    # ==========================================
    if (($now - $lastGitCheck).TotalSeconds -ge $gitCheckInterval) {
        $lastGitCheck = $now
        try {
            $updateInfo = Check-GitUpdate

            if ($updateInfo.HasUpdate) {
                Write-Host "[$(Get-Timestamp)] Git更新を検出！" -ForegroundColor Green
                Write-Host "  前回: $($updateInfo.LocalCommit.Substring(0,7))" -ForegroundColor Gray
                Write-Host "  最新: $($updateInfo.RemoteCommit.Substring(0,7))" -ForegroundColor Gray

                Apply-GitUpdate $updateInfo
                Start-DesktopMascot
                Start-Sleep -Milliseconds 500
                Play-Sound $successSound
                Write-Host "[$(Get-Timestamp)] Desktop Mascot 起動完了！" -ForegroundColor Cyan
            }
            else {
                Write-Host "[$(Get-Timestamp)] Git更新なし" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "[$(Get-Timestamp)] Gitチェックエラー: $_" -ForegroundColor Red
        }
    }

    # ==========================================
    # 2. トリガーファイル監視（update_signal.txt）
    # ==========================================
    if (Test-Path $triggerFilePode) {
        Write-Host "[$(Get-Timestamp)] トリガーファイルを検知！" -ForegroundColor Green

        # トリガーファイルを即削除（連打防止）
        Remove-Item $triggerFilePode -Force

        # 実行_pode版.bat を起動
        Start-PodeApp
        Start-Sleep -Milliseconds 500
        Play-Sound $successSound
        Write-Host "[$(Get-Timestamp)] 実行_pode版.bat 起動完了！" -ForegroundColor Cyan
    }

    Start-Sleep -Seconds $checkInterval
}
