# Desktop Mascot - 自動更新監視スクリプト
# このスクリプトをタスクスケジューラに登録して定期実行してください

param(
    [string]$RepoPath = "C:\hako",
    [string]$TriggerFile = "$env:USERPROFILE\Desktop\mascot-update-trigger.txt",
    [int]$CheckInterval = 60  # 秒
)

Write-Host "Desktop Mascot 更新監視を開始します..."
Write-Host "リポジトリ: $RepoPath"
Write-Host "トリガーファイル: $TriggerFile"
Write-Host "チェック間隔: ${CheckInterval}秒"
Write-Host ""

Set-Location $RepoPath

# 現在のコミットハッシュを取得
$lastCommit = git rev-parse HEAD

while ($true) {
    try {
        # リモートの変更を取得
        git fetch origin main --quiet 2>$null

        # リモートのmainの最新コミット
        $remoteCommit = git rev-parse origin/main 2>$null

        if ($remoteCommit -and $remoteCommit -ne $lastCommit) {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 新しい更新を検出しました!"

            # mainブランチに切り替えてpull
            git checkout main --quiet 2>$null
            git pull origin main --quiet 2>$null

            # トリガーファイルを作成
            $updateInfo = @"
Desktop Mascot Update Detected
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Commit: $remoteCommit
Previous: $lastCommit
"@
            $updateInfo | Out-File -FilePath $TriggerFile -Encoding UTF8

            Write-Host "トリガーファイルを作成しました: $TriggerFile"

            $lastCommit = $remoteCommit
        }
        else {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 更新なし" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] エラー: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds $CheckInterval
}
