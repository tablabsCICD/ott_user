# Apple wallet purchase verification contract

The Flutter application uses StoreKit 2 and sends the Apple-signed transaction
JWS from `PurchaseDetails.verificationData.serverVerificationData`. The backend
must not pass this JWS to Apple's deprecated `verifyReceipt` endpoint.

## Endpoint

`POST /api/apple-iap/verify-wallet-purchase` with the authenticated JWT.

```json
{
  "platform": "ios",
  "productId": "com.filmytell.wallet.99",
  "purchaseId": "2000001204242986",
  "transactionId": "2000001204242986",
  "transaction_id": "2000001204242986",
  "originalTransactionId": null,
  "verificationData": "<StoreKit 2 transaction JWS>",
  "verificationSource": "app_store",
  "transactionDate": "1784000000000",
  "userId": 5,
  "deviceId": "<canonical authenticated device ID>"
}
```

`userId` is correlation metadata. Resolve the wallet owner exclusively from
the JWT and reject any mismatch. Never accept an amount from the client.

## Required verification

Prefer local verification of Apple's signed JWS using Apple's certificate
chain, or call App Store Server API `Get Transaction Info` using the supplied
transaction ID. Keep issuer ID, key ID, private key and bundle ID on the server.

Before crediting, validate:

- signature/server response and environment;
- bundle ID `com.filmytell.ott`;
- exact configured product ID;
- transaction ID and product type;
- transaction is not revoked or refunded;
- transaction has not been delivered to another user.

Map product IDs to wallet amounts on the server. Current Flutter product IDs
are `com.filmytell.wallet.99`, `.199`, `.499`, and `.999`; these must exactly
match App Store Connect.

## Idempotent delivery

Add a unique constraint on `(payment_platform, external_transaction_id)`.
Within one database transaction: create/find the verified purchase, credit the
JWT user's wallet once, insert the wallet ledger entry, and mark delivery. Roll
back all changes if any step fails. A replay returns the original successful
result with `alreadyProcessed: true`.

```json
{
  "success": true,
  "verified": true,
  "alreadyProcessed": false,
  "transactionId": "2000001204242986",
  "productId": "com.filmytell.wallet.99",
  "creditedAmount": 99,
  "walletBalance": 1099,
  "environment": "Sandbox"
}
```

The Flutter app completes the StoreKit transaction only after this verified
response. Both first delivery and an idempotent replay must return all fields.

## Environment routing and diagnostics

Use the environment in the verified JWS. Sandbox/TestFlight transactions go to
the Sandbox App Store Server API; production purchases go to Production. Do
not try both environments for arbitrary errors.

Safe success log:

```text
apple_verify product=com.filmytell.wallet.99 transaction=***242986 environment=Sandbox verified=true already_processed=false
```

Safe failure log:

```text
apple_verify product=com.filmytell.wallet.99 transaction=***242986 environment=Sandbox code=APPLE_BUNDLE_ID_MISMATCH verified=false
```

Never log the JWS, receipt, JWT, Apple authorization token or private key.
