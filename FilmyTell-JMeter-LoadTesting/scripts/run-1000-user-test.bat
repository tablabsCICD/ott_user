@echo off
REM FilmyTell OTT Load Testing - 1000 User High Concurrency Load Test
set PATH=C:\apache-jmeter-5.6.3\bin;%PATH%
set TEST_PLAN=..\jmeter\FilmyTell_Load_Test.jmx
set RESULT_FILE=..\results\1000_user_results.jtl
set REPORT_DIR=..\reports\1000_user_report

if exist "%RESULT_FILE%" del /f "%RESULT_FILE%"
if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"

echo Starting FilmyTell 1000 Concurrent User Load Test targeting https://filmytell.com/ott ...
call jmeter.bat -n -t "%TEST_PLAN%" -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=1000 -JRAMP_UP=300 -JDURATION=600 -l "%RESULT_FILE%" -e -o "%REPORT_DIR%"

echo 1000 User Load test complete. Report generated at %REPORT_DIR%\index.html
pause
