# ==========================================
# トリガーファイル監視スクリプト
# デスクトップのトリガーファイルを監視し、
# 対応するアプリを起動する
# ==========================================

# ==========================================
# 設定: ファイルとフォルダの場所
# ==========================================
$desktop = [Environment]::GetFolderPath("Desktop")

# トリガーファイル（2種類）
$triggerFileMascot = "$desktop\mascot_update_signal.txt"
$triggerFilePode = "$desktop\update_signal.txt"

# 音声ファイルの場所
$soundFolder = "C:\Users\hello\Documents\Sounds"
$successSound = "$soundFolder\success.wav"

# Desktop Mascotのパス
$repoPath = "C:\hako"

# 実行_pode版.batのパス
$podeAppPath = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell\実行_pode版.bat"
$podeAppWorkDir = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\UIpowershell"

# チェック間隔（秒）
$checkInterval = 1

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
# 関数: Desktop Mascotアプリを起動
# ==========================================
function Start-DesktopMascot {
    # 既存のアプリプロセスを終了
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
# 関数: 実行_pode版.batを起動
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
Write-Host " トリガーファイル監視"
Write-Host "=========================================="
Write-Host "[$(Get-Timestamp)] 監視を開始しました..."
Write-Host "トリガー1: $triggerFileMascot → Desktop Mascot"
Write-Host "トリガー2: $triggerFilePode → 実行_pode版.bat"
Write-Host "チェック間隔: ${checkInterval}秒"
Write-Host ""

while ($true) {
    # ==========================================
    # 1. mascot_update_signal.txt → Desktop Mascot
    # ==========================================
    if (Test-Path $triggerFileMascot) {
        Write-Host "[$(Get-Timestamp)] mascot_update_signal.txt を検知！" -ForegroundColor Green

        # トリガーファイルを削除（連打防止）
        Remove-Item $triggerFileMascot -Force

        # Desktop Mascot を起動
        Start-DesktopMascot
        Start-Sleep -Milliseconds 500
        Play-Sound $successSound

        Write-Host "[$(Get-Timestamp)] Desktop Mascot 起動完了！" -ForegroundColor Cyan
    }

    # ==========================================
    # 2. update_signal.txt → 実行_pode版.bat
    # ==========================================
    if (Test-Path $triggerFilePode) {
        Write-Host "[$(Get-Timestamp)] update_signal.txt を検知！" -ForegroundColor Green

        # トリガーファイルを削除（連打防止）
        Remove-Item $triggerFilePode -Force

        # 実行_pode版.bat を起動
        Start-PodeApp
        Start-Sleep -Milliseconds 500
        Play-Sound $successSound

        Write-Host "[$(Get-Timestamp)] 実行_pode版.bat 起動完了！" -ForegroundColor Cyan
    }

    Start-Sleep -Seconds $checkInterval
}
