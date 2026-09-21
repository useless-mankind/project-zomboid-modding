#Requires -Version 5.1
<#
.SYNOPSIS
    从 docs/ 重建单文件完整版手册。

.DESCRIPTION
    本仓库的手册有两个形态，内容必须一致：
      - docs/       拆分版（每章一个文件，供在线阅读与跳转）
      - handbook/   单文件完整版（供离线阅读与全文搜索）

    以 docs/ 为唯一事实源。改完 docs/ 后运行本脚本重新生成 handbook/。

.NOTES
    本文件必须保存为 UTF-8 with BOM —— Windows PowerShell 5.1 读取无 BOM 的 .ps1
    会按 ANSI 解码，脚本里的中文会变成乱码并导致语法错误。

.EXAMPLE
    .\tools\sync-handbook.ps1
#>

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$docs = Join-Path $repo "docs"
$out  = Join-Path $repo "handbook\ProjectZomboid-Mod开发速查手册.md"

if (-not (Test-Path $docs)) { throw "找不到 docs 目录: $docs" }

# 单文件版前言（拆分版没有这段，只存在于此处）
$front = @(
    '# Project Zomboid Mod 开发速查手册',
    '',
    '> **适用版本**：Build 42.20.x（官方首页实时显示 Stable 42.20.4 / Unstable 42.20.4）',
    '> **B42 转正时间**：2026-07-29 由 unstable 进入 Stable 分支',
    '> **整理日期**：2026-09',
    '> **证据等级约定**：本手册内容标注来源，`[官方文档]` = TIS 发布或官方 Javadoc，`[社区文档]` = 社区自动生成的 API 文档，`[论坛]` = 官方论坛玩家实测帖。凡我推断的会明确写「推断」。'
)

# 读入一章，去掉页眉页脚注释与首尾空白/分隔线
function LoadDoc($file) {
    $p = Join-Path $docs $file
    if (-not (Test-Path $p)) { throw "缺少文件: $file" }
    $lines = Get-Content $p -Encoding UTF8
    $body = $lines | Where-Object {
        $_ -notmatch '^<!--' -and $_ -notmatch '^> :book: \[返回总目录\]'
    }
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($l in $body) { $list.Add($l) }
    while ($list.Count -gt 0 -and $list[$list.Count - 1].Trim() -eq '') { $list.RemoveAt($list.Count - 1) }
    while ($list.Count -gt 0 -and $list[$list.Count - 1].Trim() -eq '---') {
        $list.RemoveAt($list.Count - 1)
        while ($list.Count -gt 0 -and $list[$list.Count - 1].Trim() -eq '') { $list.RemoveAt($list.Count - 1) }
    }
    while ($list.Count -gt 0 -and $list[0].Trim() -eq '') { $list.RemoveAt(0) }
    return $list
}

# 07 号文件里装了 §9 与 §11 两章，需在 §11 处切开才能还原正确顺序
$d07 = LoadDoc '07-调试与发布.md'
$splitAt = -1
for ($i = 0; $i -lt $d07.Count; $i++) {
    if ($d07[$i] -match '^##\s*11\.') { $splitAt = $i; break }
}
if ($splitAt -lt 0) { throw '在 07-调试与发布.md 中找不到 §11 标题' }
$d07a = $d07[0..($splitAt - 1)]
$d07b = $d07[$splitAt..($d07.Count - 1)]

# 组装顺序：§0–§9 → §10 → §11 → §12 → §13 → 附录 A → 附录 B → 待确认 → 附录 C
$order = @(
    @{ doc = '01-快速起步与环境.md';    part = 'all' },
    @{ doc = '02-Mod类型与选题.md';      part = 'all' },
    @{ doc = '03-目录结构与mod.info.md'; part = 'all' },
    @{ doc = '04-脚本层-物品与配方.md';  part = 'all' },
    @{ doc = '05-Lua层-事件与钩子.md';   part = 'all' },
    @{ doc = '06-翻译.md';               part = 'all' },
    @{ doc = '07-调试与发布.md';         part = 'a'   },
    @{ doc = '08-踩坑清单.md';           part = 'all' },
    @{ doc = '07-调试与发布.md';         part = 'b'   },
    @{ doc = '12-枪械与弹药系统.md';     part = 'all' },
    @{ doc = '13-大型mod工程结构.md';    part = 'all' },
    @{ doc = '09-模板生成脚本.md';       part = 'all' },
    @{ doc = '10-数据获取与研究设施.md'; part = 'all' },
    @{ doc = '11-参考资料与待确认.md';   part = 'all' }
)

$parts = @()
foreach ($item in $order) {
    switch ($item.part) {
        'a'   { $parts += ($d07a -join "`n") }
        'b'   { $parts += ($d07b -join "`n") }
        default { $parts += ((LoadDoc $item.doc) -join "`n") }
    }
}
$body = $parts -join "`n`n---`n`n"

# 单文件内不需要跨文件链接，还原为纯文本引用
$body = [regex]::Replace($body, '\[([^\]]+)\]\((?:0[1-9]|1[0-2])-[^)]*\.md\)', '$1')

$text = (($front -join "`n") + "`n`n---`n`n" + $body) + "`n"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
[System.IO.File]::WriteAllText($out, $text, (New-Object System.Text.UTF8Encoding $false))

Write-Host "已重建单文件版本: $out"
Write-Host "行数: $((Get-Content $out -Encoding UTF8).Count)"
Write-Host ''
Write-Host '章节顺序:'
Get-Content $out -Encoding UTF8 | Select-String -Pattern '^##\s' | ForEach-Object { "  " + $_.Line }
