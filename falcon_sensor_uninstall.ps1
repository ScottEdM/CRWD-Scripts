$RegPath = if ((Get-CimInstance win32_operatingsystem).OSArchitecture -eq '64-bit') {
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
} else {
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
}
if (Test-Path $RegPath) {
    $Values = foreach ($Key in (Get-ChildItem $RegPath | Where-Object {
        $_.GetValue('DisplayName') -match 'CrowdStrike(.+)?Sensor'
    })) {
        [PSCustomObject] @{
            Version = $Key.GetValue('DisplayVersion')
            String  = if ($Key.GetValue('QuietUninstallString')) {
                $Key.GetValue('QuietUninstallString')
            } else {
                $Key.GetValue('UninstallString')
            }
        }
    }
    if (($Values | Measure-Object).Count -gt 1) {
        $Total = ($Values | Measure-Object).Count - 1
        $Values | Sort-Object Version | Select-Object -First $Total | ForEach-Object {
            cmd /c "$($_.String)"
        }
    } elseif (($Values | Measure-Object).Count -eq 1) {
        cmd /c "$($Values.String)"
    } else {
        throw "No 'UninstallString' found for 'CrowdStrike Sensor'."
    }
}