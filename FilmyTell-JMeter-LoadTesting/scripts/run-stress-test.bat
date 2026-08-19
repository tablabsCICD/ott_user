@echo off
REM FilmyTell OTT Load Testing - Stress Test (500 Users)
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\09-stress-test.jmx
set RESULT_FILE=..\results\stress_results.jtl
set REPORT_DIR=..\reports\stress_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo WARNING: Starting Stress Test (500 Users)...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=500 -JRAMP_UP=600 -JDURATION=1800 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo Stress test complete. Report generated at %REPORT_DIR%\index.html
pause
