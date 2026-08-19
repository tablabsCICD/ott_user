@echo off
REM FilmyTell OTT Load Testing - Endurance Test (50 Users, 2 Hours)
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\10-endurance-test.jmx
set RESULT_FILE=..\results\endurance_results.jtl
set REPORT_DIR=..\reports\endurance_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo Starting Endurance Test (50 Users for 2 Hours)...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=50 -JRAMP_UP=180 -JDURATION=7200 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo Endurance test complete. Report generated at %REPORT_DIR%\index.html
pause
