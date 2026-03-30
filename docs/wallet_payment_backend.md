# Wallet Payment Backend Flow

## 1. Create Razorpay Order

Endpoint:
`GET /api/razorpay/create-order?amount={amount}&customerId={userId}`

Suggested logic:

```js
app.get('/api/razorpay/create-order', async (req, res) => {
  const amount = Number(req.query.amount);
  const customerId = Number(req.query.customerId);

  if (!amount || amount <= 0 || !customerId) {
    return res.status(400).json({ success: false, message: 'Invalid request' });
  }

  const order = await razorpay.orders.create({
    amount: Math.round(amount * 100),
    currency: 'INR',
    receipt: `wallet_${customerId}_${Date.now()}`,
    notes: { customerId: String(customerId), source: 'wallet_topup' },
  });

  return res.json({
    success: true,
    data: {
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt,
    },
  });
});
```

## 2. Verify Payment And Credit Wallet

Endpoint:
`POST /api/razorpay/verify-payment`

Rules:
- Verify HMAC signature on the backend only.
- Reject duplicate `transactionId` or already-processed `razorPayOrderId`.
- Credit wallet only after verification succeeds.
- Save a `credit` transaction row with provider metadata.

Suggested logic:

```js
app.post('/api/razorpay/verify-payment', async (req, res) => {
  const {
    amount,
    plan,
    razorPayOrderId,
    signature,
    transactionId,
    userId,
  } = req.body;

  const payload = `${razorPayOrderId}|${transactionId}`;
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(payload)
    .digest('hex');

  if (expected !== signature) {
    return res.status(400).json({ success: false, message: 'Invalid signature' });
  }

  const alreadyProcessed = await paymentRepo.findByTransactionId(transactionId);
  if (alreadyProcessed) {
    return res.json({ success: true, message: 'Payment already verified' });
  }

  await db.transaction(async (trx) => {
    await paymentRepo.insertVerifiedPayment(trx, {
      userId,
      transactionId,
      razorPayOrderId,
      signature,
      amount,
      plan,
      type: 'credit',
      status: 'success',
    });

    await walletRepo.credit(trx, {
      userId,
      amount,
      reason: 'Wallet top-up',
      transactionType: 'credit',
    });
  });

  return res.json({ success: true, message: 'Payment verified successfully' });
});
```

## 3. Wallet Deduct For Purchase

Endpoint:
`POST /api/wallet/deduct`

Rules:
- Check wallet balance inside a DB transaction.
- Deduct only once for a purchase.
- Save debit transaction.
- Grant content access in the same transaction when possible.

Suggested logic:

```js
app.post('/api/wallet/deduct', async (req, res) => {
  const { userId, amount, contentId } = req.body;

  await db.transaction(async (trx) => {
    const balance = await walletRepo.getBalanceForUpdate(trx, userId);
    if (balance < amount) {
      throw new Error('INSUFFICIENT_BALANCE');
    }

    await walletRepo.debit(trx, {
      userId,
      amount,
      reason: `Purchase content ${contentId}`,
      transactionType: 'debit',
    });

    await purchaseRepo.grantAccess(trx, {
      userId,
      contentId,
      price: amount,
      status: 'Paid',
    });
  });

  return res.json({ success: true, message: 'Wallet deducted successfully' });
});
```

## 4. Razorpay Payout To Client

Run payout after successful purchase.

Rules:
- Resolve content owner from `contentId`.
- Load the owner's `fund_account_id`.
- Create payout with Razorpay.
- Save payout record.
- If payout fails, compensate according to your business rule:
  either immediate wallet refund or mark for retry queue.

Suggested logic:

```js
async function payoutToClient({ purchaseId, ownerId, amount, contentId }) {
  const owner = await creatorRepo.getOwnerForPayout(ownerId);
  if (!owner?.fundAccountId) {
    throw new Error('MISSING_FUND_ACCOUNT');
  }

  const payout = await razorpay.payouts.create({
    account_number: process.env.RAZORPAY_X_ACCOUNT_NUMBER,
    fund_account_id: owner.fundAccountId,
    amount: Math.round(amount * 100),
    currency: 'INR',
    mode: 'IMPS',
    purpose: 'payout',
    queue_if_low_balance: true,
    reference_id: `content_${contentId}_purchase_${purchaseId}`,
    narration: 'FilmyTell content payout',
  });

  await payoutRepo.insert({
    purchaseId,
    ownerId,
    contentId,
    amount,
    payoutId: payout.id,
    status: payout.status,
    type: 'payout',
  });

  return payout;
}
```

## 5. Failure Handling

- If purchase succeeds but payout fails, do not silently lose the event.
- Save payout status as `failed` or `pending`.
- Refund wallet only if your business policy requires atomic purchase+payout.
- Prefer a retry queue for transient payout failures.
- Add idempotency checks on:
  - Razorpay payment verification
  - Wallet debit
  - Purchase grant
  - Payout creation
