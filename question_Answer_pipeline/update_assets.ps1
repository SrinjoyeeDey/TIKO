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

$pubspecLines = Get-Content $pubspecPath
$newPubspec = @()
$inAssetsSection = $false
$assetsAdded = $false

# Discover all level folders (folders inside chapter folders)
$assetPaths = @()
Get-ChildItem -Path $assetsDir -Directory | ForEach-Object {
    $chapter = $_.Name
    $assetPaths += "    - assets/$chapter/"
    Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
        $level = $_.Name
        $assetPaths += "    - assets/$chapter/$level/"
        
        if (Test-Path "$($_.FullName)/images") {
            $assetPaths += "    - assets/$chapter/$level/images/"
        }
    }
}

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
            foreach ($path in $assetPaths) {
                $newPubspec += $path
            }
            $assetsAdded = $true
            $newPubspec += $line
        } else {
            # Empty lines or other things in assets section, keep them
            if (-not $assetsAdded -and $line.Trim() -eq "") {
                # Add assets before the first empty line if we haven't already
                foreach ($path in $assetPaths) {
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
    foreach ($path in $assetPaths) {
        $newPubspec += $path
    }
}

Set-Content -Path $pubspecPath -Value $newPubspec
Write-Host "Successfully updated pubspec.yaml with dynamically discovered assets!" -ForegroundColor Green
