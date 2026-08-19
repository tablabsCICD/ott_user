# FilmyTell OTT — Authentication & Correlation Specification

## Authentication Flow Sequence

```
[1. Send OTP] (GET /userNew/SendOTPOnMobileWithRegistration)
       │
       ▼
[2. Verify OTP JWT] (GET /userNew/VerifyOtpJWT)
       │
       ├──► Extracts: accessToken  ($.data.token)
       ├──► Extracts: tokenType    ($.data.tokenType -> Default: Bearer)
       ├──► Extracts: sessionId    ($.data.sessionId)
       └──► Extracts: userId       ($.data.userId)
       │
       ▼
[3. Authenticated Samplers]
       Header: Authorization: ${tokenType} ${accessToken}
```

## Correlation Rules
- **No Hardcoded Tokens**: Dynamic tokens extracted from `VerifyOtpJWT` are passed to all subsequent API requests.
- **Cookies**: Handled automatically via JMeter HTTP Cookie Manager.
