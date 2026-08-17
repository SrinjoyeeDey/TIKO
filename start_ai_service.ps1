Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Starting NIMO Python AI Service (Port 8001)..." -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan

$pythonCmd = "python"
if (Test-Path ".venv\Scripts\python.exe") {
    $pythonCmd = ".venv\Scripts\python.exe"
}

Write-Host "Checking Python dependencies..." -ForegroundColor Yellow
if (Test-Path "requirements.txt") {
    & $pythonCmd -m pip install -r requirements.txt
} else {
    & $pythonCmd -m pip install -r ai_services/nimo_contract_api/requirements.txt
}

Write-Host ""
Write-Host "Launching FastAPI server on http://localhost:8001..." -ForegroundColor Green
Write-Host "Interactive Swagger docs: http://localhost:8001/docs" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan

$env:PYTHONPATH = ".;ai_services"
& $pythonCmd -m uvicorn ai_services.nimo_contract_api.main:app --reload --port 8001
