// Verifies the app tells the user the server is unreachable, instead of a
// generic "Sign up failed", when the API can't be reached.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:earthi_naturals/core/theme/app_theme.dart';
import 'package:earthi_naturals/data/api/api_client.dart';
import 'package:earthi_naturals/data/api/api_providers.dart';
import 'package:earthi_naturals/features/auth/signup_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup with an unreachable API names the real problem',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Nothing is listening on 4999 — same failure the phone hit when the
        // dev server was down.
        apiClientProvider.overrideWithValue(
            ApiClient(baseUrl: 'http://127.0.0.1:4999/api')),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const SignupScreen()),
          GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Rishika');
    await tester.enterText(find.byType(TextField).at(1), '9381464897');
    await tester.enterText(find.byType(TextField).at(2), 'r@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'Rishika@1');
    await tester.enterText(find.byType(TextField).at(4), 'Rishika@1');

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    expect(find.text('Sign up failed'), findsNothing);
  });
}
