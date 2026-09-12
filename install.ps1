#Requires -Version 7.0
[CmdletBinding()]
param([switch]$NoPause, [switch]$Elevated, [string]$GamePath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InstallerScript = $PSCommandPath
$InstallerSource = Join-Path $PSScriptRoot 'payload'
if (-not $GamePath) {
    $steamPath = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam').SteamPath
    $GamePath = Join-Path $steamPath 'steamapps/common/OnimushaWotS'
}
$InstallerDestination = [IO.Path]::GetFullPath($GamePath)
if (-not (Test-Path -LiteralPath (Join-Path $InstallerDestination 'OnimushaWotS.exe'))) { throw '未找到 OnimushaWotS.exe；请使用 -GamePath 指定游戏目录。' }
if (-not (Test-Path -LiteralPath (Join-Path $InstallerDestination 'dinput8.dll'))) { throw '请先安装兼容的 REFramework。' }
$InstallerFiles = @('reframework/achievement_tracker/catalog.lua', 'reframework/achievement_tracker/controller.lua', 'reframework/achievement_tracker/hints.lua', 'reframework/achievement_tracker/i18n.lua', 'reframework/achievement_tracker/language_runtime.lua', 'reframework/achievement_tracker/licenses/NotoSansSC-OFL.txt', 'reframework/achievement_tracker/location_catalog.lua', 'reframework/achievement_tracker/map_model.lua', 'reframework/achievement_tracker/map_points.lua', 'reframework/achievement_tracker/map_runtime.lua', 'reframework/achievement_tracker/model.lua', 'reframework/achievement_tracker/runtime.lua', 'reframework/achievement_tracker/view.lua', 'reframework/autorun/onimusha_achievement_tracker.lua', 'reframework/fonts/onimusha_tracker_sans.ttf')

function Resolve-InstallFile([string]$Root, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':')) { throw "需要相对文件名：$Relative" }
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $path = [IO.Path]::GetFullPath((Join-Path $rootPath $Relative))
    if (-not $path.StartsWith($rootPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "文件超出安装目录：$Relative" }
    $cursor = $path
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "安装路径含链接：$cursor" }
        $cursor = Split-Path $cursor -Parent
    }
    return $path
}

function Get-InstallHash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }

function Get-InstallPlan([string]$Source, [string]$Destination, [string[]]$Files) {
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "源目录不存在：$Source" }
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) { throw "目标目录不存在：$Destination" }
    if (-not $Files.Count) { throw '安装清单不能为空。' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Files) {
        $sourceFile = Resolve-InstallFile $Source $name
        $targetFile = Resolve-InstallFile $Destination $name
        if (-not $seen.Add($targetFile)) { throw "重复目标：$name" }
        if ($sourceFile -eq $targetFile) { throw '源和目标不能相同。' }
        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) { throw "缺少源文件：$name" }
        if ((Test-Path -LiteralPath $targetFile) -and -not (Test-Path -LiteralPath $targetFile -PathType Leaf)) { throw "目标被目录占用：$name" }
        [pscustomobject]@{ Name = $name; Source = $sourceFile; Target = $targetFile; SourceHash = Get-InstallHash $sourceFile; PreviousHash = if (Test-Path -LiteralPath $targetFile) { Get-InstallHash $targetFile } else { $null } }
    }
}

function Test-InstallAccess($Plan, [string]$Destination) {
    # 只有访问权限拒绝才提权；锁定、磁盘等错误直接暴露。
    $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    [void]$directories.Add([IO.Path]::GetFullPath($Destination))
    foreach ($file in $Plan) {
        if ($file.PreviousHash) {
            if ((Get-Item -LiteralPath $file.Target).IsReadOnly) { throw "目标文件只读：$($file.Name)" }
            $stream = [IO.File]::Open($file.Target, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
            $stream.Dispose()
        }
        $directory = Split-Path $file.Target -Parent
        while (-not (Test-Path -LiteralPath $directory -PathType Container)) { $directory = Split-Path $directory -Parent }
        [void]$directories.Add($directory)
    }
    foreach ($directory in $directories) {
        $probe = Join-Path $directory ('.install-probe-' + [guid]::NewGuid().ToString('N'))
        $stream = $null
        try { $stream = [IO.File]::Open($probe, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None) }
        finally { if ($stream) { $stream.Dispose(); Remove-Item -LiteralPath $probe -Force } }
    }
}

function Invoke-ElevatedInstall([string]$Script) {
    $pwsh = (Get-Command pwsh.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $major = & $pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.Major'
    if ($LASTEXITCODE -ne 0 -or [int]$major -lt 7) { throw '未找到可运行的 PowerShell 7。' }
    $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -NoPause -GamePath "{1}"' -f $Script,$InstallerDestination
    $process = Start-Process -FilePath $pwsh -Verb RunAs -WindowStyle Hidden -ArgumentList $arguments -Wait -PassThru
    return $process.ExitCode
}

function Invoke-InstallTransaction($Plan, [string]$Destination) {
    $backupRoot = Resolve-InstallFile $Destination ('.install-backups/' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    foreach ($file in $Plan) {
        if ($file.PreviousHash) {
            $backup = Resolve-InstallFile (Join-Path $backupRoot 'files') $file.Name
            New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $file.Target -Destination $backup
            if ((Get-InstallHash $backup) -ne $file.PreviousHash) { throw '备份期间目标发生变化。' }
        }
    }
    $Plan | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backupRoot 'manifest.json') -Encoding utf8NoBOM
    $written = [Collections.Generic.List[object]]::new()
    $createdDirectories = [Collections.Generic.List[string]]::new()
    try {
        foreach ($file in $Plan) {
            if ((Get-InstallHash $file.Source) -ne $file.SourceHash) { throw "源文件发生变化：$($file.Name)" }
            $currentHash = if (Test-Path -LiteralPath $file.Target) { Get-InstallHash $file.Target } else { $null }
            if ($currentHash -ne $file.PreviousHash) { throw "目标发生变化：$($file.Name)" }
            $parent = Split-Path $file.Target -Parent
            $missing = [Collections.Generic.List[string]]::new()
            while (-not (Test-Path -LiteralPath $parent)) { $missing.Add($parent); $parent = Split-Path $parent -Parent }
            for ($i = $missing.Count - 1; $i -ge 0; $i--) { New-Item -ItemType Directory -Path $missing[$i] | Out-Null; $createdDirectories.Add($missing[$i]) }
            $written.Add($file)
            Copy-Item -LiteralPath $file.Source -Destination $file.Target -Force
            if ((Get-InstallHash $file.Target) -ne $file.SourceHash) { throw "安装哈希不符：$($file.Name)" }
        }
        foreach ($file in $Plan) { if ((Get-InstallHash $file.Target) -ne $file.SourceHash) { throw "最终哈希不符：$($file.Name)" } }
    } catch {
        $failure = $_.Exception.Message
        $restoreErrors = [Collections.Generic.List[string]]::new()
        for ($i = $written.Count - 1; $i -ge 0; $i--) {
            $file = $written[$i]
            try {
                if ($file.PreviousHash) {
                    $backup = Resolve-InstallFile (Join-Path $backupRoot 'files') $file.Name
                    if ((Get-InstallHash $backup) -ne $file.PreviousHash) { throw '备份哈希错误。' }
                    Copy-Item -LiteralPath $backup -Destination $file.Target -Force
                    if ((Get-InstallHash $file.Target) -ne $file.PreviousHash) { throw '恢复哈希错误。' }
                } elseif (Test-Path -LiteralPath $file.Target -PathType Leaf) { Remove-Item -LiteralPath $file.Target -Force }
            } catch { $restoreErrors.Add("$($file.Name): $($_.Exception.Message)") }
        }
        for ($i = $createdDirectories.Count - 1; $i -ge 0; $i--) {
            try { [IO.Directory]::Delete($createdDirectories[$i], $false) } catch { $restoreErrors.Add($_.Exception.Message) }
        }
        if ($restoreErrors.Count) { throw "安装失败：$failure；恢复未完成：$($restoreErrors -join '; ')；备份：$backupRoot" }
        throw "安装失败，已恢复原文件并移除本次新增文件：$failure；备份：$backupRoot"
    }
    Write-Host "安装完成并验证；备份：$backupRoot" -ForegroundColor Green
}

function Invoke-Installer {
    try {
        $plan = @(Get-InstallPlan $InstallerSource $InstallerDestination $InstallerFiles)
        try { Test-InstallAccess $plan $InstallerDestination }
        catch [UnauthorizedAccessException] {
            if ($Elevated) { throw '提权后仍无法写入目标。' }
            $code = Invoke-ElevatedInstall $InstallerScript
            if ($code -ne 0) { Write-Warning "提权安装进程失败，退出码：$code"; return $code }
            foreach ($file in $plan) { if ((Get-InstallHash $file.Target) -ne $file.SourceHash) { throw '子进程退出成功但安装结果不符。' } }
            Write-Host '提权安装结果已独立验证。' -ForegroundColor Green
            return 0
        }
        Invoke-InstallTransaction $plan $InstallerDestination
        return 0
    } catch { Write-Warning $_.Exception.Message; return 1 }
}

if ($MyInvocation.InvocationName -ne '.') {
    $code = Invoke-Installer
    if (-not $NoPause) { [void](Read-Host '按 Enter 关闭') }
    exit $code
}

