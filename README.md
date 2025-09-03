# Claude Auto Scheduler

自動執行 `claude -p 'hi'` 指令，配合 Claude 每5小時重製週期。

## 支援平台

- **Windows**: PowerShell + Task Scheduler
- **Linux**: Bash + Cron

## 快速開始

### Windows
```cmd
windows.bat
```

### Linux
```bash
./linux.sh
```

## 執行時間

每5小時執行一次：
- 07:30, 12:30, 17:30, 22:30

## 時區設定

### Linux
預設 UTC+8，可修改 `claude_scheduler.sh` 中的 `TIMEZONE`

### Windows
使用系統時區

## 自訂設定

### 修改時間
```bash
# Linux: 編輯 claude_scheduler.sh
SCHEDULE_TIMES=("08:00" "13:00" "18:00" "23:00")

# Windows: 編輯 claude_scheduler.ps1
$scheduleTimes = @("08:00", "13:00", "18:00", "23:00")
```

### 修改指令
```bash
# Linux
COMMAND_TO_RUN="your command"

# Windows
$commandToRun = "your command"
```

## 日誌查看

- `scheduled_task.log` - 主日誌
- `output.log` - 命令輸出
- `error.log` - 錯誤訊息

## 移除任務

### Windows
```cmd
schtasks /delete /tn Claude_0730 /f
schtasks /delete /tn Claude_1230 /f
schtasks /delete /tn Claude_1730 /f
schtasks /delete /tn Claude_2230 /f
```

### Linux
```bash
crontab -e  # 刪除相關行
```

## 檔案說明

- `claude_scheduler.ps1` - Windows 腳本
- `windows.bat` - Windows 設定工具
- `claude_scheduler.sh` - Linux 腳本
- `linux.sh` - Linux 設定工具
