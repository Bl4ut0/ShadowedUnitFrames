param(
    [Parameter(Mandatory = $true)]
    [string]$BaseArchive,

    [Parameter(Mandatory = $true)]
    [string]$OutputArchive
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$basePath = (Resolve-Path -LiteralPath $BaseArchive).Path
$outputPath = [System.IO.Path]::GetFullPath($OutputArchive)
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ('suf-forever-' + [guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    Expand-Archive -LiteralPath $basePath -DestinationPath $stage

    $mainAddon = Join-Path $stage 'ShadowedUnitFrames'
    $optionsAddon = Join-Path $stage 'ShadowedUF_Options'
    if (-not (Test-Path -LiteralPath (Join-Path $mainAddon 'libs\AceDB-3.0\AceDB-3.0.lua')) -or
        -not (Test-Path -LiteralPath (Join-Path $optionsAddon 'libs\AceConfig-3.0\AceConfig-3.0.lua'))) {
        throw 'The base archive must contain both packaged addons and their libraries.'
    }

    $trackedFiles = & git -C $repoRoot ls-files
    if ($LASTEXITCODE -ne 0) { throw 'Could not list the tracked addon source files.' }

    foreach ($relative in $trackedFiles) {
        if ($relative -match '^(\.github/|scripts/|\.)' -or $relative -eq 'FOREVER.md') { continue }
        $source = Join-Path $repoRoot ($relative.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }

        if ($relative.StartsWith('options/')) {
            $target = Join-Path $optionsAddon ($relative.Substring(8).Replace('/', '\'))
        } else {
            $target = Join-Path $mainAddon ($relative.Replace('/', '\'))
        }
        $parent = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $mainToc = Get-Content -LiteralPath (Join-Path $mainAddon 'ShadowedUnitFrames.toc') -TotalCount 1
    $optionsToc = Get-Content -LiteralPath (Join-Path $optionsAddon 'ShadowedUF_Options.toc') -TotalCount 1
    if ($mainToc -notmatch '16001' -or $optionsToc -notmatch '16001') {
        throw 'Both addon TOCs must include Forever interface 16001.'
    }

    $outputDir = Split-Path -Parent $outputPath
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    Compress-Archive -Path (Join-Path $stage 'ShadowedUnitFrames'), (Join-Path $stage 'ShadowedUF_Options') -DestinationPath $outputPath -Force
    Write-Output $outputPath
} finally {
    $resolvedStage = [System.IO.Path]::GetFullPath($stage)
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedStage.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedStage)) {
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
