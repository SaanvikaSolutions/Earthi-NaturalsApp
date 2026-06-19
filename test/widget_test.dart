import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earthi_naturals/core/router/app_router.dart';
import 'package:earthi_naturals/core/theme/app_theme.dart';

void main() {
  testWidgets('App boots to the login screen', (tester) async {

    
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
  });
}
