# Define the maximum usages you would like to track (in percentage)
$CPUThreshold = 75  # CPU usage in percentage
$MemoryThreshold = 80  # Memory usage in percentage

# Define the log file location where you will track the logs in a single csv file
$LogFilePath = "C:\ProcessMonitoring\ProcessLog.csv"

# Create log directory if it doesn't exist
if (!(Test-Path -Path (Split-Path $LogFilePath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFilePath)
}

# Infinite loop for continuous monitoring
while ($true) {
    # Monitor processes
    $Processes = Get-Process | ForEach-Object {
        $CPU = ($_.CPU / (Get-WmiObject Win32_ComputerSystem).NumberOfProcessors)
        $Memory = ($_.WorkingSet / 1MB)
        [PSCustomObject]@{
            Name      = $_.Name
            CPU       = [math]::Round($CPU, 2)
            MemoryMB  = [math]::Round($Memory, 2)
        }
    }

    # Filter processes exceeding thresholds
    $HighUsageProcesses = $Processes | Where-Object {
        $_.CPU -ge $CPUThreshold -or $_.MemoryMB -ge $MemoryThreshold
    }

    # Log data
    foreach ($Process in $HighUsageProcesses) {
        $LogEntry = "$(Get-Date),$($Process.Name),$($Process.CPU),$($Process.MemoryMB)"
        Add-Content -Path $LogFilePath -Value $LogEntry
    }

    # Send desktop notifications for high-usage processes
    if ($HighUsageProcesses) {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $ToastXml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $ToastTextNodes = $ToastXml.GetElementsByTagName("text")
        $ToastTextNodes.Item(0).AppendChild($ToastXml.CreateTextNode("Process Alert"))
        $ToastTextNodes.Item(1).AppendChild($ToastXml.CreateTextNode("High CPU/Memory usage detected."))
        $Toast = [Windows.UI.Notifications.ToastNotification]::new($ToastXml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Process Monitor").Show($Toast)
    }

    # Sleep for a minute before the next check
    Start-Sleep -Seconds 30
}
