#Requires -Version 7.0
[CmdletBinding()]
param([string]$GamePath,[switch]$NoPause)
$ErrorActionPreference='Stop'
$code=0
try {
    # 复用相同的路径约束及安装清单，只删除本 Mod 的文件。
    . (Join-Path $PSScriptRoot 'install.ps1') -GamePath $GamePath -NoPause
    $names=@($InstallerFiles)+@('reframework/fonts/onimusha_tracker_zh.ttc')
    $backupRoot=Resolve-InstallFile $InstallerDestination ('.install-backups/tracker-uninstall-'+[guid]::NewGuid().ToString('N'))
    $plan=@(foreach($name in $names) {
        $target=Resolve-InstallFile $InstallerDestination $name
        if(Test-Path -LiteralPath $target -PathType Leaf) {
            [pscustomobject]@{Name=$name;Target=$target;Hash=Get-InstallHash $target;Backup=Resolve-InstallFile $backupRoot $name}
        }
    })
    foreach($file in $plan) {
        New-Item -ItemType Directory -Path (Split-Path $file.Backup -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.Target -Destination $file.Backup
        if((Get-InstallHash $file.Backup) -ne $file.Hash) {throw '卸载备份验证失败。'}
    }
    $removed=[Collections.Generic.List[object]]::new()
    try {
        foreach($file in $plan) {
            if((Get-InstallHash $file.Target) -ne $file.Hash) {throw '卸载期间文件发生变化。'}
            Remove-Item -LiteralPath $file.Target -Force
            $removed.Add($file)
        }
    } catch {
        foreach($file in $removed) {
            Copy-Item -LiteralPath $file.Backup -Destination $file.Target -Force
            if((Get-InstallHash $file.Target) -ne $file.Hash) {throw "卸载回滚失败：$($file.Target)；备份：$backupRoot"}
        }
        throw
    }
    Write-Host "已卸载 $($plan.Count) 个 Mod 文件；偏好设置与游戏存档保留。" -ForegroundColor Green
    Write-Host "重启游戏后生效。备份：$backupRoot"
} catch {Write-Warning $_.Exception.Message;$code=1}
if(-not $NoPause){[void](Read-Host '按 Enter 关闭')}
exit $code
