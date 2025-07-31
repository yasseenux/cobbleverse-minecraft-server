@echo off
REM Cobbleverse Server Management Script for Windows
REM Usage: server.bat [start|stop|restart|logs|backup|update]

set SERVER_NAME=cobbleverse-server
set BACKUP_DIR=.\backups
set WORLD_DIR=.\world

if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="logs" goto logs
if "%1"=="backup" goto backup
if "%1"=="update" goto update
goto usage

:start
echo Starting Cobbleverse server...
docker-compose up -d
goto end

:stop
echo Stopping Cobbleverse server...
docker-compose down
goto end

:restart
echo Restarting Cobbleverse server...
docker-compose restart
goto end

:logs
echo Showing server logs...
docker-compose logs -f
goto end

:backup
echo Creating world backup...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"
tar -czf "%BACKUP_DIR%\world_backup_%timestamp%.tar.gz" "%WORLD_DIR%"
echo Backup created: %BACKUP_DIR%\world_backup_%timestamp%.tar.gz
goto end

:update
echo Updating server...
docker-compose down
docker-compose build --no-cache
docker-compose up -d
goto end

:usage
echo Usage: %0 {start^|stop^|restart^|logs^|backup^|update}
echo.
echo Commands:
echo   start   - Start the server
echo   stop    - Stop the server
echo   restart - Restart the server
echo   logs    - Show server logs
echo   backup  - Create world backup
echo   update  - Update and rebuild server

:end
