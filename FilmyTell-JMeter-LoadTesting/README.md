# FilmyTell OTT — Production Load Testing Framework (`https://filmytell.com/ott`)

A complete, production-grade load testing suite built with **Apache JMeter 5.6+** for the FilmyTell OTT platform. All endpoints, HTTP methods, parameters, authentication mechanisms, dynamic token correlation, and data structures are strictly mapped from the source code (`lib/app/core/constant/api_constant.dart`).

---

## 📁 Repository Directory Structure

```
FilmyTell-JMeter-LoadTesting/
├── jmeter/
│   ├── FilmyTell_Load_Test.jmx       # Master End-to-End Test Plan
│   ├── 01-authentication.jmx         # Send OTP, Verify OTP & JWT Token Extraction
│   ├── 02-home-browse.jmx            # Dashboard Filters & Public Top/Latest Content
│   ├── 03-content.jmx                # Movie & Series Details, Cast Information
│   ├── 04-search.jmx                 # Search & Filter by Language/Genre/Rating
│   ├── 05-user-profile.jmx           # User Profile, Continue Watching & Bookmarks
│   ├── 06-playback.jmx               # Anti-Piracy Playback Security & Signed URLs
│   ├── 07-notifications.jmx          # User Push Notifications
│   ├── 08-end-to-end-user-flow.jmx   # Complete User Journey
│   ├── 09-stress-test.jmx            # Stepped Concurrency (100 -> 500 users)
│   └── 10-endurance-test.jmx         # Sustained Load / Soak Test (2-4 Hours)
│
├── data/
│   ├── users.csv                     # Test User Mobile Numbers, Device IDs, User IDs
│   ├── content.csv                   # Content IDs & Content Types (MOVIE, SERIES, etc.)
│   └── devices.csv                   # Device Types (ANDROID, IOS, WEB, TV) & Metadata
│
├── config/
│   └── performance-thresholds.properties # Performance SLA Thresholds
│
├── reports/                          # Generated HTML Dashboard & Client Reports
│   └── FilmyTell_Load_Test_Client_Report.html
│
├── results/                          # Raw JTL Execution Logs
│
├── scripts/
│   ├── run-smoke-test.bat            # 1-User Validation Script
│   ├── run-baseline-test.bat         # 10-User Baseline Script
│   ├── run-load-test.bat             # 100-User Normal/Heavy Load Script
│   ├── run-stress-test.bat           # 500-User Stepped Stress Script
│   ├── run-endurance-test.bat        # 2-Hour Soak Test Script
│   └── run-load-test.sh              # Linux / macOS CLI Script
│
├── documentation/
│   ├── API_DISCOVERY_REPORT.md       # Full Discovered API Matrix from Code
│   ├── AUTHENTICATION_FLOW.md        # Authentication & Token Correlation Spec
│   ├── TEST_PLAN.md                  # Test Plan Specification
│   ├── TEST_DATA_REQUIREMENTS.md     # CSV Data Requirements
│   └── CLIENT_REPORT_TEMPLATE.md     # Client Report Template
│
└── README.md                         # Detailed Instructions & SLA Guidelines
```

---

## 🎯 Target Environment Configuration

All test plans use JMeter User Defined Variables targeting `https://filmytell.com/ott`:

| Variable | Default Value | Resolved URL |
| :--- | :--- | :--- |
| `BASE_PROTOCOL` | `https` | `https://filmytell.com/ott` |
| `BASE_HOST` | `filmytell.com` | `https://filmytell.com/ott` |
| `BASE_PATH` | `/ott` | `https://filmytell.com/ott` |
| `BASE_URL` | `${BASE_PROTOCOL}://${BASE_HOST}${BASE_PATH}` | **`https://filmytell.com/ott`** |

To override via CLI:
```cmd
jmeter.bat -n -t ..\jmeter\FilmyTell_Load_Test.jmx -JBASE_HOST=filmytell.com -JBASE_PATH=/ott -JTHREAD_COUNT=10
```

---

## 🚨 How to Run the First Test

> [!IMPORTANT]
> **ALWAYS run a 1-User Smoke Test first.** Never run high-concurrency load tests directly against any environment without verifying basic API functionality.

### Step 1: Execute the 1-User Smoke Test via CLI
Open Command Prompt:
```cmd
d:
cd "d:\Tablab Workspace\OTT\ott_user\FilmyTell-JMeter-LoadTesting\scripts"
run-smoke-test.bat
```

### Step 2: Validate Results
1. Confirm 0 failed requests in `..\results\smoke_results.jtl`.
2. Open `..\reports\FilmyTell_Load_Test_Client_Report.html` in Chrome or Edge.

### Step 3: Scale Load Gradually
Only after the 1-user test passes cleanly, scale concurrency step-by-step:
$$\text{1 User (Smoke)} \longrightarrow \text{10 Users (Baseline)} \longrightarrow \text{50 Users (Normal)} \longrightarrow \text{100 Users (Heavy)} \longrightarrow \text{500 Users (Stress)}$$

---

## 🔐 Security & Safety Rules

1. **Never Log Credentials**: OTPs, JWT tokens, and signed playback URLs are masked in logs and reports.
2. **Non-GUI Execution**: Always run load tests via CLI mode (`-n`). JMeter GUI is exclusively for test plan design and debugging.
3. **No Video Stream Flooding**: Playback signed URL APIs are load-tested separately from raw media streaming.
