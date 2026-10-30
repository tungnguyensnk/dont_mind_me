[CmdletBinding()]
param(
    [string]$Output = "out/dont_mind_me.zip",
    [switch]$RemoveMerged
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $root $Output
$outputName = [IO.Path]::GetFileName($outputPath)
$outputDirectory = Split-Path -Parent $outputPath

if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if ($RemoveMerged) {
    $mergedPath = Join-Path $root "classes.dex.merged"
    if (Test-Path -LiteralPath $mergedPath) {
        Remove-Item -LiteralPath $mergedPath -Force
        Write-Host "Removed classes.dex.merged"
    }
}

if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

$oldRootZip = Join-Path $root "dont_mind_me.zip"
if ($outputPath -ne $oldRootZip -and (Test-Path -LiteralPath $oldRootZip)) {
    Remove-Item -LiteralPath $oldRootZip -Force
}

$excluded = @(
    ".git",
    ".idea",
    ".claude",
    ".impeccable",
    ".gitignore",
    "_dexbuild",
    "out",
    $outputName,
    "classes.dex.merged",
    "Bridge.java",
    "check_webui.js",
    "build.ps1"
)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
# exclude any root-level .zip (source module zips, stray build outputs); the module ships none
$items = Get-ChildItem -LiteralPath $root -Force |
    Where-Object { $_.Name -notin $excluded -and $_.Extension -ne ".zip" }
$files = foreach ($item in $items) {
    if ($item.PSIsContainer) {
        Get-ChildItem -LiteralPath $item.FullName -File -Recurse
    } else {
        $item
    }
}
# gms/src holds the libgmsspoof native sources (built separately); don't ship them
$files = $files | Where-Object { $_.FullName -notmatch '[\\/]gms[\\/]src[\\/]' }

# Compress-Archive writes Windows backslashes into ZIP entry names. Android
# module installers require POSIX-style '/' separators, so create each entry
# explicitly with a normalized relative path.
$archive = [IO.Compression.ZipFile]::Open($outputPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $file.FullName,
            $entryName,
            [IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
} finally {
    $archive.Dispose()
}

$archive = [IO.Compression.ZipFile]::OpenRead($outputPath)
try {
    $names = @($archive.Entries | ForEach-Object { $_.FullName })
    if ($names -notcontains "classes.dex") {
        throw "classes.dex is missing from the module archive"
    }
    if ($names -contains "classes.dex.merged") {
        throw "classes.dex.merged must not be included in the module archive"
    }
    $backslashNames = @($names | Where-Object { $_.Contains('\') })
    if ($backslashNames.Count -gt 0) {
        throw "ZIP contains Windows-style entry paths: $($backslashNames -join ', ')"
    }
} finally {
    $archive.Dispose()
}

$file = Get-Item -LiteralPath $outputPath
$hash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
Write-Host "Built $($file.Name) ($($file.Length) bytes)"
Write-Host "SHA-256: $hash"
