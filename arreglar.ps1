# Buscamos archivos 'code' o 'code.html' y los renombramos a 'index.html'
$archivos = Get-ChildItem -Recurse -File | Where-Object { $_.Name -eq 'code' -or $_.Name -eq 'code.html' }
$links = @()

Write-Host "--- INICIANDO LA MAGIA ---" -ForegroundColor Cyan

foreach ($archivo in $archivos) {
    $carpeta = $archivo.Directory
    $nuevoNombre = Join-Path $carpeta.FullName "index.html"
    
    # Renombrar el archivo
    Rename-Item $archivo.FullName $nuevoNombre
    Write-Host "✅ Listo: $($carpeta.Name)" -ForegroundColor Green
    
    # Crear el enlace para tu menú
    $nombreLimpio = $carpeta.Name -replace "ivyco_", "" -replace "_", " "
    $nombreLimpio = (Get-Culture).TextInfo.ToTitleCase($nombreLimpio)
    
    $linkHTML = "<li><a href='$($carpeta.Name)/index.html'>$nombreLimpio</a></li>"
    $links += $linkHTML
}

Write-Host "`n--- COPIA ESTO EN TU HTML ---" -ForegroundColor Yellow
$links | ForEach-Object { Write-Host $_ }
Write-Host "-----------------------------------" -ForegroundColor Yellow