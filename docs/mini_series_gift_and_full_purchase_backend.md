# Mini Series: Gifting and One-Time Full Purchase — Backend Contract

## Current status (2026-11-23): gift contract published as typed Swagger schemas

Source: `http://ec2-13-201-27-141…:8080/ott/v2/api-docs`, `MiniSeriesGift*`
definitions. All gift endpoints are integrated in the app:

| Endpoint | Schema | App |
|---|---|---|
| `GET api/mini-series/{id}/gift-details` | `MiniSeriesGiftDetails` | Gift sheet: price, min/max quantity, `giftAvailable` |
| `POST api/mini-series/gift/purchase` + `Idempotency-Key` | `MiniSeriesGiftPurchaseRequest {miniSeriesId, quantity, paymentMethod:"WALLET"}` → `MiniSeriesGiftPurchaseData` | Confirm & Pay; codes shown with copy/share; 400 `MiniSeriesInsufficientBalanceData`, 404, 409 handled |
| `POST api/mini-series/gift/claim` | `MiniSeriesGiftClaimRequest {giftCode}` → `MiniSeriesGiftClaimData` | Existing claim dialog routes `MSG-` codes here; 403/404/409/410 show the backend message |
| `GET api/mini-series/gift/history` | `MiniSeriesGiftHistoryItem[]` | Profile → Mini Series Gifts → Sent |
| `GET api/mini-series/gift/received` | `MiniSeriesGiftReceivedItem[]` | Profile → Mini Series Gifts → Received |

All dates are epoch milliseconds. The sections below are historical.

### Received gifts: sender and expiry (resolved 2026-11-23)

`MiniSeriesGiftReceivedItem` now has `senderName` (nullable, shown as
"Gifted by: {name}", or "Gifted by: A friend" when null or blank) and
`giftExpiryDate` (epoch ms, the same value as `expiryDate`, which is kept for
compatibility). `giftExpiryDate` is the **claim deadline of the gift code**,
not the recipient's access period. Received items are already claimed, so the
app shows it only on unclaimed items, labelled "Gift code expiry date".

### Open backend request: access validity on received gifts

The recipient's access end date (`accessValidUntil`) is returned only by
`POST gift/claim`, not by `GET gift/received`. The app never derives it from
the gift-code expiry, so after a refresh it cannot show "Access valid until".
**Request:** add `accessValidUntil` (epoch ms) to each `MiniSeriesGiftReceivedItem`.
The app already reads that field name and shows it when present.

## Original proposal (superseded — kept for reference)

**Status: PROPOSED — superseded by the real endpoints above.**

The Flutter app has a frontend integration built against this contract. It is
hidden behind a compile-time flag that is **off by default**:

```
flutter run --dart-define=ENABLE_MINI_SERIES_COMMERCE=true
```

Until the backend confirms (or changes) these endpoints, release builds do not
show the new buttons and never call these URLs. If the final contract differs,
update `ApiConstant` (mini series section), `MiniSeriesCommerceService`, and
`mini_series_commerce_models.dart` only.

## Why new endpoints are needed

- A mini series is a `shortsMaster` record, not a `Content` record. The current
  gift API `POST api/saveMovieGiftMaster` takes `movieId` (a `Content` ID).
  Sending a `shortsMaster` ID there would gift whichever movie happens to share
  that ID, so it must not be reused.
- Today a part is bought with `PUT api/shortsMaster/purchaseShort?partId&userId`,
  which deducts the wallet on the server. There is no endpoint that buys every
  part in one transaction.
- The mini series detail response has no gift price and no full-purchase price.

## Conventions (same as existing shortsMaster APIs)

- Base URL: the existing `baseUrl`. `Authorization: Bearer <JWT>` header.
- Envelope: `{ "success": bool, "message": string, "errorCode"?: string, "data": {...} }`.
- Money: decimal numbers in INR, the same unit as `coins` and wallet balance.
- The **server** computes every price. The client sends an `expected…` amount
  only so the server can reject a stale price (`PRICE_CHANGED`).
- Wallet deduction, ownership grant and transaction record must be one atomic
  server-side operation, like `purchaseShort` and `series/purchase/season`.
  The client does **not** call `/deduct` separately.
- `idempotencyKey` (UUID v4, generated per checkout attempt): a repeat request
  with the same key must return the original result and must not charge again.

## 1. Purchase quote

`GET api/shortsMaster/{shortId}/purchase-quote?userId={userId}`

Returns the current prices for this user. Owned parts and free-preview parts are
excluded from `fullPurchasePrice`.

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "shortId": 12,
    "title": "Example Drama",
    "currency": "INR",
    "totalParts": 10,
    "purchasablePartCount": 8,
    "ownedPartCount": 1,
    "freePartCount": 1,
    "parts": [
      { "partId": 101, "partNumber": 1, "price": 0,  "free": true,  "owned": false, "purchasable": false },
      { "partId": 102, "partNumber": 2, "price": 20, "free": false, "owned": true,  "purchasable": false },
      { "partId": 103, "partNumber": 3, "price": 20, "free": false, "owned": false, "purchasable": true }
    ],
    "fullPurchasePrice": 160.0,
    "fullPurchaseAvailable": true,
    "alreadyOwnsAll": false,
    "giftAvailable": true,
    "giftPrice": 200.0,
    "minGiftCount": 1,
    "maxGiftCount": 10
  }
}
```

- `fullPurchasePrice` = sum of `price` over parts with `purchasable: true`.
- `giftPrice` is the price of one gift of the whole mini series. It is set by the
  backend and is independent of this user's owned parts.
- `maxGiftCount` may be `null` for no limit.

## 2. Buy full mini series

`PUT api/shortsMaster/purchaseFull?shortId={shortId}&userId={userId}&expectedAmount={amount}&idempotencyKey={uuid}`

Server: recompute the price, then reject with `PRICE_CHANGED` if it differs from
`expectedAmount`. Check the wallet, deduct once, grant every purchasable part, and
write **one** purchase transaction (purchase history shows a single row of type
`MINI_SERIES`).

Success:

```json
{
  "success": true,
  "message": "Mini series purchased",
  "data": {
    "transactionId": "TXN-123",
    "shortId": 12,
    "coinsDeducted": 160.0,
    "newBalance": 40.0,
    "unlockedPartIds": [103, 104, 105]
  }
}
```

Failure: `success: false` with an `errorCode`:

| errorCode | Meaning |
|---|---|
| `INSUFFICIENT_BALANCE` | Wallet balance is lower than the price |
| `PRICE_CHANGED` | `expectedAmount` no longer matches; client re-fetches the quote |
| `ALREADY_OWNED` | Nothing left to buy (treated as success by the client) |
| `NOT_AVAILABLE` | Full purchase is disabled for this mini series |

## 3. Gift mini series

`POST api/shortsMaster/gift`

```json
{
  "giftOwnerId": 3,
  "shortId": 12,
  "totalGiftCount": 3,
  "expectedTotal": 600.0,
  "idempotencyKey": "5b0c…"
}
```

Server: `totalPaid = giftPrice × totalGiftCount`, computed server-side. Validate
the min/max count, then check and deduct the wallet atomically. Create the gift
master with `contentType: "MINI_SERIES"` and generate the claim coupon(s) the same
way as for movie gifts.

```json
{
  "success": true,
  "message": "Gift created",
  "data": {
    "giftMasterId": 55,
    "shortId": 12,
    "totalGiftCount": 3,
    "totalPaid": 600.0,
    "newBalance": 25.0,
    "couponCode": "GIFT-ABCD"
  }
}
```

Error codes: `INSUFFICIENT_BALANCE`, `PRICE_CHANGED`, `INVALID_GIFT_COUNT`, `NOT_AVAILABLE`.

## 4. Changes needed in existing endpoints

| Endpoint | Change |
|---|---|
| `GET api/shortsMaster/{id}?userId` | Return `isPurchased: true` for parts unlocked by a full purchase or a claimed gift |
| `POST anti-piracy/playback/signed-url` (type `SHORT_PART`) | Authorize parts owned through a full purchase or gift |
| `GET api/getByGiftOwner`, `GET api/getByGiftMasterId` | For mini series gifts: `contentType: "MINI_SERIES"` plus `short: { id, title, poster }` (`movie` stays null) |
| `POST api/useGiftByCoupon` | Claiming a mini series gift grants every part to the recipient |
| Gifted-to-you / remaining-days and `api/purchase-history` | Include mini series entries with `contentType: "MINI_SERIES"` and `short: {…}` |

## Frontend status

| Item | Status |
|---|---|
| Buy Full Mini Series sheet (quote, breakdown, wallet check, purchase, unlock refresh) | Built, behind flag |
| Gift sheet (quantity, price per gift, total, wallet check, purchase) | Built, behind flag |
| Gift history / Gifted To You / claim display for `MINI_SERIES` | **Pending**: needs the confirmed response shape from section 4 |
| Purchase history row for `MINI_SERIES` | **Pending**: same reason |
