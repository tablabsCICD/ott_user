import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';

void main() {
  testWidgets('header back returns to the profile menu', (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileDetailShell(
          title: 'Wallet',
          onBack: () => backCount++,
          child: Scaffold(
            appBar: AppBar(title: Text('Wallet')),
          ),
        ),
      ),
    );

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    expect(backCount, 1);
  });

  testWidgets('escape key invokes the same profile back action',
      (tester) async {
    var backCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileDetailShell(
          title: 'Registered Devices',
          onBack: () => backCount++,
          child: Scaffold(
            appBar: AppBar(title: Text('Registered Devices')),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backCount, 1);
  });
}
