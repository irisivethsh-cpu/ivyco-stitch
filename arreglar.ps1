$ErrorActionPreference = 'Stop'

function Add-AfterHeadIfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$Html,
        [Parameter(Mandatory = $true)][string]$ExistsPattern,
        [Parameter(Mandatory = $true)][string]$Snippet
    )

    if ($Html -match $ExistsPattern) {
        return $Html
    }

    return [regex]::Replace(
        $Html,
        '(?is)(<head\b[^>]*>)',
        {
            param($m)
            $m.Groups[1].Value + "`r`n" + $Snippet
        },
        1
    )
}

function Ensure-BodyClass {
    param(
        [Parameter(Mandatory = $true)][string]$Html
    )

    return [regex]::Replace(
        $Html,
        '(?is)<body\b[^>]*>',
        '<body class="bg-ivory text-dark antialiased font-sans">',
        1
    )
}

function Add-BackButtonIfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$Html,
        [Parameter(Mandatory = $true)][string]$ButtonHtml
    )

    if ($Html -match '(?is)href\s*=\s*[^>]*\.\./index\.html' -and $Html -match '(?is)Volver al Inicio') {
        return $Html
    }

    return [regex]::Replace(
        $Html,
        '(?is)(<body\b[^>]*>)',
        {
            param($m)
            $m.Groups[1].Value + "`r`n" + $ButtonHtml
        },
        1
    )
}

$rootPath = (Get-Location).Path
$rootIndexPath = Join-Path $rootPath 'index.html'

$headViewport = '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
$headTailwindCdn = '<script src="https://cdn.tailwindcss.com"></script>'
$headFonts = '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400&family=Playfair+Display:wght@600&display=swap" rel="stylesheet">'
$headTailwindConfig = @'
<script>
  tailwind.config = {
        theme: { extend: { colors: { ivory: '#faf7f2', gold: '#b08d57', dark: '#1a1a1a' } } }
  }
</script>
'@

$backButton = '<a href="../index.html" class="fixed top-4 left-4 z-50 px-4 py-2 bg-white/30 backdrop-blur-md border border-white/40 rounded-full text-sm font-medium hover:bg-white/50 transition-all shadow-sm">← Volver al Inicio</a>'

$files = Get-ChildItem -Path $rootPath -Recurse -File -Filter 'index.html' |
    Where-Object { $_.FullName -ne $rootIndexPath }

if (-not $files) {
    Write-Host 'No se encontraron index.html en subcarpetas.' -ForegroundColor Yellow
    exit 0
}

$updated = 0
$skipped = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $original = $content

    if ($content -notmatch '(?is)<head\b[^>]*>' -or $content -notmatch '(?is)<body\b[^>]*>') {
        Write-Host "⚠ Saltado (sin <head> o <body>): $($file.FullName)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $content = Add-AfterHeadIfMissing -Html $content -ExistsPattern '(?is)<meta[^>]*name\s*=\s*[^>]*viewport[^>]*>' -Snippet $headViewport
    $content = Add-AfterHeadIfMissing -Html $content -ExistsPattern '(?is)<script[^>]*src\s*=\s*[^>]*cdn\.tailwindcss\.com[^>]*>\s*</script>' -Snippet $headTailwindCdn
    $content = Add-AfterHeadIfMissing -Html $content -ExistsPattern '(?is)<link[^>]*href\s*=\s*[^>]*fonts\.googleapis\.com/css2\?family=Inter:wght@300;400&family=Playfair\+Display:wght@600&display=swap[^>]*>' -Snippet $headFonts

    if ($content -notmatch '(?is)tailwind\.config\s*=') {
        $content = Add-AfterHeadIfMissing -Html $content -ExistsPattern '(?is)<script[^>]*>\s*tailwind\.config\s*=' -Snippet $headTailwindConfig.Trim()
    }

    $content = Ensure-BodyClass -Html $content
    $content = Add-BackButtonIfMissing -Html $content -ButtonHtml $backButton

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "✅ Arreglado: $($file.FullName)" -ForegroundColor Green
        $updated++
    }
    else {
        Write-Host "• Sin cambios: $($file.FullName)" -ForegroundColor DarkGray
        $skipped++
    }
}

Write-Host "`nCompletado. Arreglados: $updated | Sin cambios/saltados: $skipped" -ForegroundColor Cyan