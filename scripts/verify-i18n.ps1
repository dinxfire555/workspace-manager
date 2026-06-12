param(
    [string]$Path = ".",
    [string[]]$Exclude = @("README-vi.md", "QUICKSTART-vi.md")
)

Write-Host "=== WM i18n Verification ===" -ForegroundColor Cyan

$vnCharCodes = @(
    0x00E0,0x00E1,0x1EA3,0x00E3,0x1EA1,0x00E2,0x1EA7,0x1EA5,0x1EA9,0x1EAB,0x1EAD,
    0x0103,0x1EB1,0x1EAF,0x1EB3,0x1EB5,0x1EB7,0x00E8,0x00E9,0x1EBB,0x1EBD,0x1EB9,
    0x00EA,0x1EC1,0x1EBF,0x1EC3,0x1EC5,0x1EC7,0x00EC,0x00ED,0x1EC9,0x0129,0x1ECB,
    0x00F2,0x00F3,0x1ECF,0x00F5,0x1ECD,0x00F4,0x1ED3,0x1ED1,0x1ED5,0x1ED7,0x1ED9,
    0x01A1,0x1EDB,0x1EDD,0x1EDF,0x1EE1,0x1EE3,0x00F9,0x00FA,0x1EE7,0x0169,0x1EE5,
    0x01B0,0x1EEB,0x1EE9,0x1EED,0x1EEF,0x1EF1,0x1EF3,0x00FD,0x1EF7,0x1EF9,0x1EF5,0x0111
)
$vnChars = [char[]]$vnCharCodes

$total = 0
$vn = 0

$allFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
    ($_.Extension -match '\.(ps1|sh|md|json|template)$') -and
    ($_.Name -notin $Exclude) -and
    ($_.DirectoryName -notmatch '\.git')
}

foreach ($f in $allFiles) {
    $total++
    $content = Get-Content -Path $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $hasVN = $false
    foreach ($ch in $vnChars) {
        if ($content.Contains($ch)) { $hasVN = $true; break }
    }
    if ($hasVN) {
        $vn++
        $rel = $f.FullName.Replace((Resolve-Path $Path).Path + "\", "")
        Write-Host "  [VN] $rel" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Scanned: $total files | Vietnamese: $vn files" -ForegroundColor Cyan
if ($vn -eq 0) { Write-Host "All clean!" -ForegroundColor Green }
