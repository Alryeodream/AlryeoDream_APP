import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alrim2/main.dart';
import 'package:alrim2/providers/auth_provider.dart';
import 'package:alrim2/providers/settings_provider.dart';
import 'package:alrim2/providers/benefit_provider.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await authProvider.init();

    final settingsProvider = SettingsProvider.instance;
    await settingsProvider.init();

    final benefitProvider = BenefitProvider();

    await tester.pumpWidget(AlryeodeurimApp(
      authProvider: authProvider,
      settingsProvider: settingsProvider,
      benefitProvider: benefitProvider,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}