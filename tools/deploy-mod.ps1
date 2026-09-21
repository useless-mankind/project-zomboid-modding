#Requires -Version 5.1
<#
.SYNOPSIS
    把 mods/ 下的某个 mod 部署到 Project Zomboid 的本地 mods 目录。

.DESCRIPTION
    日常开发不需要每次手动复制。两种模式：
      Copy     —— 复制一份（默认，最稳；改完要重新跑一次）
      Junction —— 建目录联结，改源码即时反映到游戏 mods 目录（推荐，需要目标卷支持）

    注意：Junction 模式下游戏读的就是仓库里的文件，别在游戏运行时删目录。

.PARAMETER Mod
    mods/ 下的目录名，默认 myspatialrefuge。

.PARAMETER ZomboidDir
    Zomboid 用户目录，默认 %USERPROFILE%\Zomboid。

.PARAMETER Mode
    Copy（默认）或 Junction。

.PARAMETER Force
    目标已存在时先删除再重建。

.EXAMPLE
    .\tools\deploy-mod.ps1
    .\tools\deploy-mod.ps1 -Mod myspatialrefuge -Mode Junction -Force

.NOTES
    本文件必须保存为 UTF-8 with BOM —— Windows PowerShell 5.1 读取无 BOM 的 .ps1
    会按 ANSI 解码，脚本里的中文会变成乱码并导致语法错误。
#>

[CmdletBinding()]
param(
    [string]$Mod = "myspatialrefuge",
    [string]$ZomboidDir = (Join-Path $env:USERPROFILE "Zomboid"),
    [ValidateSet("Copy", "Junction")]
    [string]$Mode = "Copy",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo "mods\$Mod"
$dst = Join-Path $ZomboidDir "mods\$Mod"

# --- 前置校验 ---------------------------------------------------------------

if (-not (Test-Path -LiteralPath $src)) {
    throw "找不到 mod 源码目录: $src"
}
if (-not (Test-Path -LiteralPath (Join-Path $src "mod.info"))) {
    throw "源码目录里没有 mod.info，不是合法的 mod: $src"
}

$zomboidMods = Join-Path $ZomboidDir "mods"
if (-not (Test-Path -LiteralPath $ZomboidDir)) {
    Write-Warning "没找到 Zomboid 用户目录: $ZomboidDir"
    Write-Warning "这台机器可能没装/没跑过 Project Zomboid。"
    Write-Warning "装好后确认路径，或用 -ZomboidDir 指定；本脚本不会替你把游戏装上。"
    return
}

New-Item -ItemType Directory -Force -Path $zomboidMods | Out-Null

# --- 处理已存在的目标 -------------------------------------------------------

if (Test-Path -LiteralPath $dst) {
    if (-not $Force) {
        throw "目标已存在: $dst`n如需覆盖请加 -Force（会先删除该目录）"
    }
    $item = Get-Item -LiteralPath $dst -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        # Junction / 符号链接：删链接本身，别递归删目标内容
        [void](cmd /c rmdir "`"$dst`"")
    } else {
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
    Write-Host "已删除旧目标: $dst"
}

# --- 部署 -------------------------------------------------------------------

if ($Mode -eq "Junction") {
    [void](cmd /c mklink /J "`"$dst`"" "`"$src`"")
    if ($LASTEXITCODE -ne 0) { throw "创建目录联结失败（退出码 $LASTEXITCODE）" }
    Write-Host "已建立目录联结（改源码即时生效）"
} else {
    Copy-Item -LiteralPath $src -Destination $dst -Recurse
    Write-Host "已复制到游戏 mods 目录"
}

# --- 结果 -------------------------------------------------------------------

$modInfo = Get-Content -LiteralPath (Join-Path $src "mod.info") -Encoding UTF8
$id = ($modInfo | Where-Object { $_ -match '^\s*id\s*=' } | Select-Object -First 1) -replace '^\s*id\s*=\s*', ''
$ver = ($modInfo | Where-Object { $_ -match '^\s*modversion\s*=' } | Select-Object -First 1) -replace '^\s*modversion\s*=\s*', ''

$count = (Get-ChildItem -LiteralPath $dst -Recurse -File).Count

Write-Host ""
Write-Host "  来源   : $src"
Write-Host "  目标   : $dst"
Write-Host "  模式   : $Mode"
Write-Host "  文件数 : $count"
Write-Host "  mod id : $id  (v$ver)"
Write-Host ""
Write-Host "下一步：启动游戏 → 主菜单 Mods → 勾选该 mod → 读档进入。"
Write-Host "调试：Steam 启动项填 -debug 并选 Alternate launch，报错看 $ZomboidDir\console.txt"
if ($Mode -eq "Copy") {
    Write-Host ""
    Write-Host "提示：Copy 模式下每次改完源码都要重跑本脚本；想省事用 -Mode Junction。"
}
