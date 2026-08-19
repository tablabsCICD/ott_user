@echo off
REM FilmyTell OTT Load Testing - Smoke Test (1 User)
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\FilmyTell_Load_Test.jmx
set RESULT_FILE=..\results\smoke_results.jtl
set REPORT_DIR=..\reports\smoke_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo Starting FilmyTell Smoke Test targeting https://filmytell.com/ott ...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=1 -JRAMP_UP=1 -JDURATION=60 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo Smoke test complete. Report generated at %REPORT_DIR%\index.html
pause
