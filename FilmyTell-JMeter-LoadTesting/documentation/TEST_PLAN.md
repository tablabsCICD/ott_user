# FilmyTell Load Test Plan

## Objective
Evaluate performance of FilmyTell OTT backend APIs targeting `https://filmytell.com/ott`.

## Test Scenarios
1. **Smoke Test**: 1 User, 1 Minute Ramp-up, 5 Minutes Duration.
2. **Baseline Test**: 10 Users, 60s Ramp-up, 10 Minutes Duration.
3. **Normal Load Test**: 50 Users, 300s Ramp-up, 30 Minutes Duration.
4. **High Load Test**: 100 Users, 600s Ramp-up, 30 Minutes Duration.
5. **Stress Test**: Stepped load 100 -> 200 -> 300 -> 500 Users.
6. **Endurance Test**: 50-100 Users for 2-4 Hours.
