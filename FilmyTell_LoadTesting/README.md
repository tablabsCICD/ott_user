# FilmyTell OTT — Production Load Testing Framework

A complete, production-grade load testing suite built with **Apache JMeter** for the FilmyTell OTT platform. This framework tests API performance, concurrency, throughput, response time percentiles (P90, P95, P99), authentication flows, playback signed URLs, content browsing, search, and user profile operations under realistic user traffic.

---

## 📁 Repository & Directory Structure

```
FilmyTell_LoadTesting/
├── jmeter/
│   ├── FilmyTell_Load_Test.jmx       # Master End-to-End Test Plan
│   ├── 01_authentication.jmx         # Send OTP, Verify OTP & JWT Token Extraction
│   ├── 02_home_browse.jmx            # Dashboard Filters & Public Top/Latest Content
│   ├── 03_content.jmx                # Movie & Series Details, Cast Information
│   ├── 04_search.jmx                 # Search & Filter by Language/Genre/Rating
│   ├── 05_user_profile.jmx           # User Profile, Continue Watching & Bookmarks
│   ├── 06_playback_signed_url.jmx    # Anti-Piracy Playback Security & Signed URLs
│   ├── 07_notifications.jmx          # User Push Notifications
│   ├── 08_end_to_end_user_flow.jmx   # Complete User Journey
│   ├── 09_stress_test.jmx            # Stepped Concurrency (100 -> 500 users)
│   └── 10_endurance_test.jmx         # Sustained Load / Soak Test (2-4 Hours)
│
├── data/
│   ├── users.csv                     # Test User Mobile Numbers, Device IDs, User IDs
│   ├── content.csv                   # Content IDs & Content Types (MOVIE, SERIES, etc.)
│   └── devices.csv                   # Device Types (ANDROID, IOS, WEB, TV) & Metadata
│
├── reports/                          # Generated HTML Dashboard Reports
├── results/                          # Raw JTL Execution Logs
├── scripts/
│   ├── run-smoke-test.bat            # 1-User Validation Script
│   ├── run-load-test.bat             # 100-User Normal/Heavy Load Script
│   ├── run-stress-test.bat           # Stepped Load Stress Script
│   └── run-endurance-test.bat        # 2-Hour Soak Test Script
│
└── README.md                         # Detailed Instructions & SLA Guidelines
```

---

## 🛠️ Prerequisites & Installation

1. **Java Development Kit (JDK)**:
   - JDK 11 or JDK 17+ installed. Verify with:
     ```cmd
     java -version
     ```
2. **Apache JMeter**:
   - Install Apache JMeter 5.6+ from [jmeter.apache.org](https://jmeter.apache.org/).
   - Add `<JMETER_HOME>/bin` to your system PATH or update the `set JMETER_HOME` variable in `scripts/*.bat`.

---

## ⚙️ Target Environment Configuration

All test plans use JMeter User Defined Variables and system properties (`-Jproperty=value`). Do **NOT** hardcode URLs in `.jmx` files.

| Parameter | Default Value | Command Line Property Override Example |
| :--- | :--- | :--- |
| `BASE_PROTOCOL` | `https` | `-JBASE_PROTOCOL=http` |
| `BASE_HOST` | `filmytell.in` | `-JBASE_HOST=staging.filmytell.in` |
| `BASE_PORT` | *(empty)* | `-JBASE_PORT=8080` |
| `BASE_PATH` | `/ott` | `-JBASE_PATH=/ott` |
| `ENVIRONMENT` | `QA` | `-JENVIRONMENT=STAGING` |
| `TEST_OTP` | `123456` | `-JTEST_OTP=999999` |
| `THREAD_COUNT` | `1` | `-JTHREAD_COUNT=100` |
| `RAMP_UP` | `1` | `-JRAMP_UP=300` |
| `DURATION` | `300` | `-JDURATION=1800` |

### Supported Environments
- **DEV**: Internal development instance
- **QA**: QA environment with static test OTP support
- **STAGING**: Staging environment mirroring production hardware
- **PRODUCTION**: Live environment (**Strictly Smoke Tests Only** without approval!)

---

## 🚨 How to Run the First Test

> [!IMPORTANT]
> **ALWAYS run a 1-User Smoke Test first.** Never run high-concurrency load tests directly against any environment without verifying basic API functionality.

### Step 1: Execute the 1-User Smoke Test via CLI
Open Command Prompt and run:
```cmd
cd FilmyTell_LoadTesting\scripts
run-smoke-test.bat
```
Alternatively, execute directly via `jmeter`:
```cmd
jmeter -n -t ..\jmeter\FilmyTell_Load_Test.jmx -JTHREAD_COUNT=1 -JRAMP_UP=1 -JDURATION=60 -JBASE_HOST=filmytell.in -JBASE_PATH=/ott -JENVIRONMENT=QA -l ..\results\smoke_results.jtl -e -o ..\reports\smoke_report
```

### Step 2: Validate Results
1. Check that `..\results\smoke_results.jtl` contains 0 failed requests.
2. Open `..\reports\smoke_report\index.html` in a web browser.
3. Confirm HTTP status code `200` for all API endpoints.

### Step 3: Scale Load Gradually
Only after the 1-user test passes cleanly, scale concurrency step-by-step:
$$\text{1 User} \longrightarrow \text{10 Users} \longrightarrow \text{50 Users} \longrightarrow \text{100 Users} \longrightarrow \text{200 Users} \longrightarrow \text{500 Users}$$

---

## 🚀 Running Test Scenarios

| Scenario | Users | Ramp-up | Duration | Script / Command |
| :--- | :--- | :--- | :--- | :--- |
| **Smoke Test** | 1 | 1s | 1 min | `run-smoke-test.bat` |
| **Baseline Load** | 10 | 60s | 10 mins | `jmeter -n -t ..\jmeter\FilmyTell_Load_Test.jmx -JTHREAD_COUNT=10 -JRAMP_UP=60 -JDURATION=600 -l ..\results\baseline.jtl` |
| **Normal Load** | 50 | 300s | 30 mins | `jmeter -n -t ..\jmeter\FilmyTell_Load_Test.jmx -JTHREAD_COUNT=50 -JRAMP_UP=300 -JDURATION=1800 -l ..\results\normal.jtl` |
| **Heavy Load** | 100 | 300s | 30 mins | `run-load-test.bat` |
| **Stress Test** | 100 → 500 | 600s | 30 mins | `run-stress-test.bat` |
| **Endurance/Soak**| 50 | 180s | 2-4 Hours | `run-endurance-test.bat` |

---

## 📊 Performance Acceptance Criteria (SLAs)

| Metric | Target SLA | Action if Breached |
| :--- | :--- | :--- |
| **Error Rate** | `< 1.0%` | Inspect HTTP 5xx error distribution & connection pool sizes |
| **P90 Response Time** | `< 1.5 seconds` | Optimize SQL queries & add Redis caching |
| **P95 Response Time** | `< 2.0 seconds` | Check backend thread pool & CPU utilization |
| **P99 Response Time** | `< 5.0 seconds` | Investigate DB lock contention / JVM GC pauses |
| **Throughput** | `> 200 req/sec` | Scale application instance nodes |

---

## 🔍 Categorization of Error Codes

| Error Code | Category | Root Cause & Diagnostic |
| :--- | :--- | :--- |
| **400** | Bad Request | Invalid parameter formatting or missing CSV values |
| **401** | Unauthorized | Token expired or invalid session credentials |
| **403** | Forbidden | Security constraint / DRM signature mismatch |
| **404** | Not Found | Incorrect API path or missing Content ID |
| **408** | Timeout | Client request timeout |
| **429** | Too Many Requests | Rate limiting / Anti-scraping policy triggered |
| **500** | Internal Server Error | Unhandled backend exception / DB connection error |
| **502** | Bad Gateway | Reverse proxy / Nginx unable to reach backend |
| **503** | Service Unavailable | Backend server overloaded / connection queue full |
| **504** | Gateway Timeout | Upstream service or DB query timed out |

---

## 🔐 Security & Safety Rules

1. **Never Log Credentials**: OTPs, JWT tokens, and signed playback URLs are masked in logs and reports.
2. **Non-GUI Execution**: Always run load tests via CLI mode (`-n`). JMeter GUI is exclusively for test plan design and debugging.
3. **Graceful Termination**: Stop a running test safely using `CTRL+C` or by calling `shutdown.cmd` / `stoptest.cmd` from the JMeter bin folder.
4. **No Video Stream Flooding**: The Signed Playback URL API is load-tested separately from raw video chunk downloading to avoid exhausting network infrastructure.
