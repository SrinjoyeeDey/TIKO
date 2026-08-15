@echo off
echo ===================================================
echo Starting NIMO Python AI Service (Port 8001)...
echo ===================================================
echo Checking Python dependencies...
python -m pip install -r ai_services/nimo_contract_api/requirements.txt
echo.
echo Launching FastAPI server on http://localhost:8001...
echo Interactive Swagger docs: http://localhost:8001/docs
echo ===================================================
set PYTHONPATH=.;ai_services
python -m uvicorn ai_services.nimo_contract_api.main:app --reload --port 8001
pause
