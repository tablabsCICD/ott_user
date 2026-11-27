import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/coupon_section_widget.dart';
import 'package:ott/app/widgets/purchase_confirmation_dialog.dart';
import 'package:ott/data/models/coupon/coupon_models.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  group('CouponSectionWidget UI and Interactions', () {
    testWidgets('Renders Have a coupon code input and disabled Apply button when empty', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CouponSectionWidget(
            purchaseKind: 'CONTENT',
            targetId: 101,
            originalPrice: 100.0,
            onCouponChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Have a coupon code?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      final applyButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Apply'));
      expect(applyButton.onPressed, isNull); // disabled when empty
    });

    testWidgets('Converts input text to uppercase', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CouponSectionWidget(
            purchaseKind: 'CONTENT',
            targetId: 101,
            originalPrice: 100.0,
            onCouponChanged: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'filmy20');
      await tester.pump();

      expect(find.text('FILMY20'), findsOneWidget);

      final applyButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Apply'));
      expect(applyButton.onPressed, isNotNull); // enabled when text entered
    });

    testWidgets('Renders applied coupon state with savings and price breakdown', (tester) async {
      final applied = CouponValidationData(
        couponCode: 'FILMY20',
        originalAmount: 100.0,
        discountAmount: 20.0,
        finalPayableAmount: 80.0,
        currency: 'INR',
        discountPercentage: 20.0,
      );

      bool removed = false;

      await tester.pumpWidget(
        _buildTestApp(
          CouponSectionWidget(
            purchaseKind: 'CONTENT',
            targetId: 101,
            originalPrice: 100.0,
            appliedCoupon: applied,
            onCouponRemoved: () {
              removed = true;
            },
            onCouponChanged: (_) {},
          ),
        ),
      );

      // Verify Applied badge and savings
      expect(find.text('FILMY20 ✓ Applied'), findsOneWidget);
      expect(find.text('You save ₹20.00'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Verify Itemized breakdown
      expect(find.text('Original Price'), findsOneWidget);
      expect(find.text('₹100.00'), findsOneWidget);
      expect(find.text('Coupon Discount (FILMY20)'), findsOneWidget);
      expect(find.text('-₹20.00'), findsOneWidget);
      expect(find.text('Total Payable'), findsOneWidget);
      expect(find.text('₹80.00'), findsOneWidget);

      // Test Remove action
      await tester.tap(find.text('Remove'));
      await tester.pump();
      expect(removed, isTrue);
    });
  });

  group('PurchaseConfirmationDialog UI', () {
    testWidgets('Renders complete purchase snapshot including coupon & discount', (tester) async {
      bool doneClicked = false;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                PurchaseConfirmationDialog.show(
                  ctx,
                  contentTitle: 'Second Son',
                  originalPrice: 100.0,
                  finalAmountPaid: 80.0,
                  discountAmount: 20.0,
                  couponCode: 'FILMY20',
                  paymentMethod: 'Razorpay',
                  orderReference: 'order_test_123',
                  onDone: () {
                    doneClicked = true;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Purchase Successful!'), findsOneWidget);
      expect(find.text('Second Son'), findsOneWidget);
      expect(find.text('Original Price'), findsOneWidget);
      expect(find.text('₹100.00'), findsOneWidget);
      expect(find.text('Coupon Applied'), findsOneWidget);
      expect(find.text('FILMY20'), findsOneWidget);
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('-₹20.00'), findsOneWidget);
      expect(find.text('Amount Paid'), findsOneWidget);
      expect(find.text('₹80.00'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Razorpay'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Successful'), findsOneWidget);
      expect(find.text('order_test_123'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(doneClicked, isTrue);
    });
  });
}
