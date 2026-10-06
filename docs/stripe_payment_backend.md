# Stripe Payment Gateway Backend Integration

This specification describes the **Stripe Payment Gateway** backend integration for international users (all countries other than India). The existing **Razorpay integration for India remains completely unchanged** (see `docs/wallet_payment_backend.md`).

---

## Architecture Overview

```text
India Users (IN)
  └── Razorpay -> /api/razorpay/create-order -> Checkout -> /api/razorpay/verify-payment -> Credit Wallet

Non-India Users (US, UK, CA, AU, etc.)
  └── Stripe   -> /api/stripe/create-checkout-session -> Stripe Checkout -> /api/stripe/verify-payment -> Credit Wallet
```

---

## 1. Environment Variables

Add the following environment variables to your backend `.env` configuration:

```env
# Stripe Configuration (Non-India)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_SUCCESS_URL=https://filmytell.com/payment/success?session_id={CHECKOUT_SESSION_ID}
STRIPE_CANCEL_URL=https://filmytell.com/payment/cancel
```

---

## 2. Create Stripe Checkout Session Endpoint

- **Endpoint**: `GET /api/stripe/create-checkout-session` or `POST /api/stripe/create-checkout-session`
- **Query / Body Parameters**:
  - `amount`: `number` (in currency unit, e.g. `10.00`)
  - `customerId` / `userId`: `number` (Filmytell User ID)
  - `currency`: `string` (defaults to `USD` or user's local currency)

### Example Implementation (Node.js / Express):

```js
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.get('/api/stripe/create-checkout-session', async (req, res) => {
  const amount = Number(req.query.amount);
  const customerId = Number(req.query.customerId || req.query.userId);
  const currency = (req.query.currency || 'USD').toLowerCase();

  if (!amount || amount <= 0 || !customerId) {
    return res.status(400).json({ success: false, message: 'Invalid request parameters' });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: currency,
            product_data: {
              name: 'Filmytell Wallet Top-up',
              description: `User ID: ${customerId}`,
            },
            unit_amount: Math.round(amount * 100), // Stripe accepts amount in cents
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: process.env.STRIPE_SUCCESS_URL || 'https://filmytell.com/payment/success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: process.env.STRIPE_CANCEL_URL || 'https://filmytell.com/payment/cancel',
      client_reference_id: String(customerId),
      metadata: {
        userId: String(customerId),
        source: 'wallet_topup',
      },
    });

    return res.json({
      success: true,
      data: {
        sessionId: session.id,
        orderId: session.id,
        amount: Math.round(amount * 100),
        currency: currency.toUpperCase(),
        checkoutUrl: session.url,
        receipt: `stripe_${customerId}_${Date.now()}`,
      },
    });
  } catch (error) {
    console.error('Error creating Stripe session:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});
```

---

## 3. Verify Stripe Payment And Credit Wallet

- **Endpoint**: `POST /api/stripe/verify-payment`
- **Request Body**:
  ```json
  {
    "sessionId": "cs_test_...",
    "amount": 10.0,
    "currency": "USD",
    "userId": 123,
    "plan": 0
  }
  ```

### Rules:
1. Retrieve session from Stripe API (`stripe.checkout.sessions.retrieve(sessionId)`).
2. Validate `payment_status === 'paid'`.
3. Validate `client_reference_id` or `metadata.userId` matches the requesting user.
4. Idempotency: Reject duplicate `sessionId` or already-credited transactions.
5. Credit wallet in database transaction.

### Example Implementation:

```js
app.post('/api/stripe/verify-payment', async (req, res) => {
  const { sessionId, amount, currency, userId, plan } = req.body;

  if (!sessionId || !userId) {
    return res.status(400).json({ success: false, message: 'Missing session ID or user ID' });
  }

  try {
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (session.payment_status !== 'paid') {
      return res.status(400).json({ success: false, message: 'Payment is not completed' });
    }

    const alreadyProcessed = await paymentRepo.findByTransactionId(sessionId);
    if (alreadyProcessed) {
      return res.json({ success: true, message: 'Payment already verified' });
    }

    await db.transaction(async (trx) => {
      await paymentRepo.insertVerifiedPayment(trx, {
        userId,
        transactionId: sessionId,
        gateway: 'stripe',
        paymentIntentId: session.payment_intent,
        amount,
        currency: currency || 'USD',
        plan: plan || 0,
        type: 'credit',
        status: 'success',
      });

      await walletRepo.credit(trx, {
        userId,
        amount,
        reason: 'Wallet top-up (Stripe)',
        transactionType: 'credit',
      });
    });

    return res.json({
      success: true,
      message: 'Payment verified and wallet credited successfully.',
      paymentIntentId: session.payment_intent,
    });
  } catch (error) {
    console.error('Stripe verification failed:', error);
    return res.status(500).json({ success: false, message: 'Verification failed' });
  }
});
```

---

## 4. Stripe Webhook Handler (Asynchronous Idempotent Credit)

- **Endpoint**: `POST /api/stripe/webhook`

```js
app.post('/api/stripe/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const userId = Number(session.client_reference_id || session.metadata.userId);
    const amount = session.amount_total / 100;

    const alreadyProcessed = await paymentRepo.findByTransactionId(session.id);
    if (!alreadyProcessed && userId) {
      await db.transaction(async (trx) => {
        await paymentRepo.insertVerifiedPayment(trx, {
          userId,
          transactionId: session.id,
          gateway: 'stripe',
          paymentIntentId: session.payment_intent,
          amount,
          type: 'credit',
          status: 'success',
        });
        await walletRepo.credit(trx, {
          userId,
          amount,
          reason: 'Wallet top-up (Stripe Webhook)',
          transactionType: 'credit',
        });
      });
    }
  }

  res.json({ received: true });
});
```
