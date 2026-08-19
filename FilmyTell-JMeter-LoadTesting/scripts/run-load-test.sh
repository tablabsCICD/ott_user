#!/usr/bin/env bash
# FilmyTell OTT Load Testing Script for Linux / macOS
TEST_PLAN="../jmeter/FilmyTell_Load_Test.jmx"
RESULT_FILE="../results/load_results.jtl"
REPORT_DIR="../reports/load_report"

rm -f "$RESULT_FILE"
rm -rf "$REPORT_DIR"

jmeter -n \
  -t "$TEST_PLAN" \
  -JBASE_HOST=filmytell.com \
  -JBASE_PATH=/ott \
  -JTHREAD_COUNT=50 \
  -JRAMP_UP=300 \
  -JDURATION=1800 \
  -l "$RESULT_FILE" \
  -e \
  -o "$REPORT_DIR"

echo "Load test complete. Report generated at $REPORT_DIR/index.html"
