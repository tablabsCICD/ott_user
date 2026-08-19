@echo off
REM FilmyTell OTT Load Testing - Baseline Test (10 Users)
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\FilmyTell_Load_Test.jmx
set RESULT_FILE=..\results\baseline_results.jtl
set REPORT_DIR=..\reports\baseline_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo Starting FilmyTell 10 User Baseline Test targeting https://filmytell.com/ott ...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=10 -JRAMP_UP=60 -JDURATION=300 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo 10 User Baseline test complete. Report generated at %REPORT_DIR%\index.html
pause
