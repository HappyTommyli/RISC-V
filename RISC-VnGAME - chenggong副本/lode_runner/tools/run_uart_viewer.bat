@echo off
set PORT=%1
if "%PORT%"=="" (
    echo Usage: run_uart_viewer.bat COM4
    exit /b 1
)

python "%~dp0uart_lode_runner_viewer.py" --port %PORT% --baud 115200 --scale 4
