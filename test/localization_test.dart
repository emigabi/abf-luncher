import 'dart:convert';
import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Vietnamese translations cover every message and preserve placeholders',
    () {
      final english =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final vietnamese =
          jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
              as Map<String, dynamic>;
      final messageKeys = english.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
      expect(
        vietnamese.keys.where((key) => !key.startsWith('@')).toSet(),
        messageKeys,
      );

      Set<String> placeholders(String value) => RegExp(
        r'\{(\w+)\}',
      ).allMatches(value).map((match) => match.group(1)!).toSet();

      for (final key in messageKeys) {
        expect(vietnamese[key], isA<String>(), reason: key);
        expect((vietnamese[key] as String).trim(), isNotEmpty, reason: key);
        expect(
          placeholders(vietnamese[key] as String),
          placeholders(english[key] as String),
          reason: 'Placeholder mismatch in $key',
        );
      }
    },
  );

  testWidgets('Vietnamese device locale resolves and formats messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi', 'VN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            final strings = AppLocalizations.of(context)!;
            return Scaffold(
              body: Column(
                children: [
                  Text(strings.settings),
                  Text(strings.addToFavorites),
                  Text(strings.redditIntervalHours(2)),
                  Text(strings.removeFrom('Phim')),
                  Text(strings.mediaItemCount(3)),
                  Text(strings.updateAvailableBody('1.2.0', '1.1.0')),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Thêm vào yêu thích'), findsOneWidget);
    expect(find.text('2 giờ'), findsOneWidget);
    expect(find.text('Xóa khỏi Phim'), findsOneWidget);
    expect(find.text('3 mục'), findsOneWidget);
    expect(
      find.text('Đã có phiên bản 1.2.0 (hiện tại: 1.1.0).'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'Existing locales retain English fallbacks for newly localized labels',
    () async {
      for (final code in ['en', 'es', 'tr']) {
        final strings = await AppLocalizations.delegate.load(Locale(code));
        expect(strings.addToFavorites, 'Add to Fav');
        expect(strings.mediaItemCount(3), '3 items');
        expect(
          strings.customBannerSetFailed('example'),
          'Failed to set banner: example',
        );
      }
    },
  );
}
