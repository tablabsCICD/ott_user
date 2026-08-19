@echo off
REM FilmyTell OTT Load Testing - Normal/Heavy Load Test (50-100 Users)
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\FilmyTell_Load_Test.jmx
set RESULT_FILE=..\results\load_results.jtl
set REPORT_DIR=..\reports\load_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo Starting FilmyTell Load Test (100 Users)...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=100 -JRAMP_UP=300 -JDURATION=1800 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo Load test complete. Report generated at %REPORT_DIR%\index.html
pause
