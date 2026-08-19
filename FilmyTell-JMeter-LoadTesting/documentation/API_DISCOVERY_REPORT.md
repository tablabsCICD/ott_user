# FilmyTell OTT — Source Code API Discovery Report

This report documents all backend APIs discovered from inspecting the FilmyTell Flutter codebase (`lib/app/core/constant/api_constant.dart` and relevant repositories).

| # | API Name | HTTP Method | Exact Endpoint | Authentication | Request Parameters / Payload | Response Structure | Source File | Used By |
|---|---|---|---|---|---|---|---|---|
| 1 | Send OTP | `GET` | `/userNew/SendOTPOnMobileWithRegistration` | None | `mobileNumber` (Query) | `{message, data, statusCode}` | `api_constant.dart:28` | Auth Flow |
| 2 | Verify OTP JWT | `GET` | `/userNew/VerifyOtpJWT` | None | `username`, `mobileNumber`, `otp`, `deviceId`, `deviceName`, `deviceType`, `appVersion` | `{message, data:{token, tokenType, sessionId, userId}, statusCode}` | `api_constant.dart:30` | Auth Flow |
| 3 | Session Login | `POST` | `/auth/session/login` | None | Credentials JSON | `{data:{sessionId, token}, statusCode}` | `api_constant.dart:7` | Auth Flow |
| 4 | Session Logout | `POST` | `/auth/session/logout` | Bearer Token | Headers only | `{message, statusCode}` | `api_constant.dart:11` | Logout |
| 5 | Filter Content List Type 3 | `GET` | `/api/forUser/filter/content-list/type3` | Optional | None | `{data:[...], statusCode}` | `api_constant.dart:59` | Home/Dashboard |
| 6 | Public Latest Content | `GET` | `/api/forUser/public/Content/Latest` | None | `page`, `size`, `type` | `{data:[...], statusCode}` | `api_constant.dart:91` | Home/Browse |
| 7 | Public Top 10 Content | `GET` | `/api/forUser/public/Content/TopTen` | None | None | `{data:[...], statusCode}` | `api_constant.dart:90` | Home/Browse |
| 8 | Content Details | `GET` | `/api/ContentList/getContentByIdAndUserId` | Optional | `id`, `userId` | `{data:{...}, statusCode}` | `api_constant.dart:75` | Movie Details |
| 9 | Series Details | `GET` | `/api/userSeries/{seriesId}/user-details` | Optional | `userId` | `{data:{...}, statusCode}` | `api_constant.dart:195` | Series Details |
| 10 | Cast Info | `GET` | `/api/Cast/getByContentId` | None | `contentId` | `{data:[...], statusCode}` | `api_constant.dart:77` | Movie/Series Details |
| 11 | Search Content | `GET` | `/api/forUser/user/Content/getByAnyKey` | Optional | `userId`, `keyword` | `{data:[...], statusCode}` | `api_constant.dart:83` | Search Page |
| 12 | Filter & Sort Content | `GET` | `/api/forUser/foruser/search/lag/gen/rating` | Optional | `userId`, `language`, `genre`, `minRating` | `{data:[...], statusCode}` | `api_constant.dart:85` | Filter Page |
| 13 | Signed Playback URL | `POST` | `/anti-piracy/playback/signed-url` | Bearer Token | `{"contentId", "deviceId", "playbackUrl", "country", "deviceIntegrity"}` | `{data:{signedUrl, expiresAt}, statusCode}` | `api_constant.dart:21` | Playback Security |
| 14 | User Profile | `GET` | `/user/getUser/{userId}` | Bearer Token | Path Parameter `userId` | `{data:{...}, statusCode}` | `api_constant.dart:71` | Profile Screen |
| 15 | Continue Watching | `GET` | `/continue-watching/user/{userId}` | Bearer Token | `contentType` | `{data:[...], statusCode}` | `api_constant.dart:201` | Profile/Home |
| 16 | User Bookmarks | `GET` | `/bookmarks/user/{userId}` | Bearer Token | Path Parameter `userId` | `{data:[...], statusCode}` | `api_constant.dart:211` | Profile/Bookmarks |
| 17 | Push Notifications | `GET` | `/api/notifications/user/{userId}/push` | Bearer Token | `pageNo`, `pageSize` | `{data:[...], statusCode}` | `api_constant.dart:134` | Notifications |
