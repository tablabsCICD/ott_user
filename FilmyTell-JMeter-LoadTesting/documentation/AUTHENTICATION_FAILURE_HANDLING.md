# FilmyTell OTT — Authentication Failure Handling Specification

This document describes the flow control, error handling, correlation validation, and reporting enhancements applied to the FilmyTell Apache JMeter test plan (`FilmyTell_Load_Test-corrected.jmx`).

---

## 🎯 Key Modifications Made

### 1. Mandatory Hard Authentication Checkpoint
- **Flow**: `Send OTP` $\rightarrow$ `Verify OTP` $\rightarrow$ `Validation`.
- Removed fallback default values (e.g. `NONE`, `userId=1`) from the JSON Extractor so missing token/session values cause explicit authentication failures.
- Added a **Groovy JSR223 Assertion** on `AUTH - Verify OTP` that checks `accessToken`, `sessionId`, and `userId`.
- Sets JMeter thread variable `${AUTH_SUCCESS}` to `true` on success, or `false` on failure.

### 2. If Controller Flow Guard
- All authenticated samplers (Content Details, Search, Signed Playback URL, Profile, Bookmarks, Push Notifications) are enclosed inside an **If Controller** with the condition:
  ```groovy
  ${AUTH_SUCCESS} == true
  ```
- If authentication fails for a virtual user, the authenticated API flow is **completely bypassed** for that thread, preventing false HTTP 200 successes or unauthorized API requests (`Authorization: Bearer NONE`).

### 3. Separated Transaction Reporting
Created separate parent Transaction Controllers to distinguish **Authentication Failures** from **Authenticated API Failures**:
1. `AUTH - Authentication Flow` (contains `AUTH - Send OTP`, `AUTH - Verify OTP`)
2. `API - Authenticated APIs` (contains `API - Filter Content`, `API - Content Details`, `API - Search`, `API - Signed Playback URL`, `API - User Profile`)

---

## 🚀 How to Run the Validation Scenarios

### 1-User Validation Test
```cmd
d:
cd "d:\Tablab Workspace\OTT\ott_user\FilmyTell-JMeter-LoadTesting\scripts"
run-smoke-test.bat
```

### High Concurrency Tests (10 / 100 / 1,000 Users)
```cmd
jmeter.bat -n -t ..\jmeter\FilmyTell_Load_Test-corrected.jmx -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=100 -l ..\results\100_user_results.jtl -e -o ..\reports\100_user_report
```
