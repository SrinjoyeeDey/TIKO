$pubspecPath = "pubspec.yaml"
$assetsDir = "assets"

if (-not (Test-Path $pubspecPath)) {
    Write-Host "pubspec.yaml not found." -ForegroundColor Red
    exit
}

if (-not (Test-Path $assetsDir)) {
    Write-Host "assets directory not found." -ForegroundColor Red
    exit
}

Write-Host "Scanning $assetsDir for folders containing files..." -ForegroundColor Cyan

# Recursively find all directories under assets that contain files
$directoriesWithFiles = @()

# Also check root assets dir
if ((Get-ChildItem -Path $assetsDir -File | Measure-Object).Count -gt 0) {
    $directoriesWithFiles += "    - $assetsDir/"
}

Get-ChildItem -Path $assetsDir -Directory -Recurse | ForEach-Object {
    $dir = $_
    $fileCount = (Get-ChildItem -Path $dir.FullName -File | Measure-Object).Count
    if ($fileCount -gt 0) {
        # Format path using forward slashes
        $relativePath = $dir.FullName.Substring((Resolve-Path .).Path.Length + 1) -replace '\\', '/'
        $directoriesWithFiles += "    - $relativePath/"
    }
}

Write-Host "Found $($directoriesWithFiles.Count) asset folders."

$pubspecLines = Get-Content $pubspecPath
$newPubspec = @()
$inAssetsSection = $false
$assetsAdded = $false

foreach ($line in $pubspecLines) {
    if ($line -match "^  assets:") {
        $inAssetsSection = $true
        $newPubspec += $line
        continue
    }
    
    if ($inAssetsSection) {
        if ($line -match "^    - assets/") {
            # Skip existing asset lines
            continue
        } elseif ($line -match "^  [a-zA-Z]" -or $line -match "^[a-zA-Z]") {
            # Reached a new section or end of flutter section
            $inAssetsSection = $false
            # Insert the new assets here
            foreach ($path in $directoriesWithFiles) {
                $newPubspec += $path
            }
            $assetsAdded = $true
            $newPubspec += $line
        } else {
            # Empty lines or comments in assets section, keep them
            if (-not $assetsAdded -and $line.Trim() -eq "") {
                # Add assets before the first empty line if we haven't already
                foreach ($path in $directoriesWithFiles) {
                    $newPubspec += $path
                }
                $assetsAdded = $true
            }
            $newPubspec += $line
        }
    } else {
        $newPubspec += $line
    }
}

if ($inAssetsSection -and -not $assetsAdded) {
    foreach ($path in $directoriesWithFiles) {
        $newPubspec += $path
    }
}

Set-Content -Path $pubspecPath -Value $newPubspec
Write-Host "Successfully updated pubspec.yaml with dynamically discovered assets!" -ForegroundColor Green
