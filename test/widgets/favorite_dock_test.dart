import 'package:flauncher/flauncher.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/category_clean_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../flauncher_test.dart' as fixtures;
import '../helpers.dart';

void main() {
  test(
    'dock reserves up to three visible rows without dropping favourites',
    () {
      expect(visibleFavoriteDockRows(0), 0);
      expect(visibleFavoriteDockRows(1), 1);
      expect(visibleFavoriteDockRows(6), 1);
      expect(visibleFavoriteDockRows(7), 2);
      expect(visibleFavoriteDockRows(12), 2);
      expect(visibleFavoriteDockRows(13), 3);
      expect(visibleFavoriteDockRows(18), 3);
      expect(visibleFavoriteDockRows(19), 3);
      expect(favoriteDockColumnsForScale(2 / 3), 9);
      expect(visibleFavoriteDockRows(9, columns: 9), 1);
      expect(visibleFavoriteDockRows(10, columns: 9), 2);
      expect(visibleFavoriteDockRows(18, columns: 9), 2);
      expect(visibleFavoriteDockRows(19, columns: 9), 3);
    },
  );

  for (final showNames in [false, true]) {
    testWidgets('all 12 favourites fit at 1080p with names=$showNames', (
      tester,
    ) async {
      await pumpDock(tester, count: 12, showNames: showNames);
      for (var i = 0; i < 12; i++) {
        expect(findAppCard('test.app.$i'), findsOneWidget);
        final rect = tester.getRect(findAppCard('test.app.$i'));
        expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(rect.bottom, lessThanOrEqualTo(540.0));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(960.0));
      }
      final first = tester.getRect(findAppCard('test.app.0'));
      final sixth = tester.getRect(findAppCard('test.app.5'));
      final seventh = tester.getRect(findAppCard('test.app.6'));
      expect(first.top, sixth.top);
      expect(seventh.left, first.left);
      expect(seventh.top, greaterThan(first.bottom));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in FAVORITE_ICON_SCALE_OPTIONS) {
    for (final showNames in [false, true]) {
      testWidgets('three rows fit with size=$scale and names=$showNames', (
        tester,
      ) async {
        final columns = favoriteDockColumnsForScale(scale);
        final count = columns * 3;
        await pumpDock(
          tester,
          count: count,
          iconScale: scale,
          showNames: showNames,
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 3),
        );
        for (var i = 0; i < count; i++) {
          final rect = tester.getRect(findAppCard('test.app.$i'));
          expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
          expect(rect.bottom, lessThanOrEqualTo(540.0));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(960.0));
        }
        final first = tester.getRect(findAppCard('test.app.0'));
        expect(first.width, closeTo(128 * scale, 0.01));
        expect(
          first.height,
          closeTo(67.5 * scale + (showNames ? 24 : 0), 0.01),
        );
        final secondRow = tester.getRect(findAppCard('test.app.$columns'));
        final thirdRow = tester.getRect(findAppCard('test.app.${columns * 2}'));
        expect(secondRow.left, closeTo(first.left, 0.01));
        expect(thirdRow.left, closeTo(first.left, 0.01));
        expect(thirdRow.top, greaterThan(secondRow.bottom));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('compact dock remote reaches each of the three rows', (
    tester,
  ) async {
    await pumpDock(tester, count: 27, iconScale: 2 / 3);
    expect(isAppCardFocused(tester, 'test.app.0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isAppCardFocused(tester, 'test.app.9'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(isAppCardFocused(tester, 'test.app.18'), isTrue);
    expect(
      tester.getRect(findAppCard('test.app.0')).top,
      greaterThanOrEqualTo(kToolbarHeight),
    );
    expect(
      tester.getRect(findAppCard('test.app.26')).bottom,
      lessThanOrEqualTo(540.0),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('remote moves between rows before returning to settings', (
    tester,
  ) async {
    await pumpDock(tester, count: 12);
    expect(isAppCardFocused(tester, 'test.app.0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 300));
    expect(isAppCardFocused(tester, 'test.app.6'), isTrue);
    expect(
      tester.getRect(findAppCard('test.app.0')).top,
      greaterThanOrEqualTo(kToolbarHeight),
    );
    expect(
      tester.getRect(findAppCard('test.app.11')).bottom,
      lessThanOrEqualTo(540.0),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 300));
    expect(isAppCardFocused(tester, 'test.app.0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rapid Down presses reveal favourites beyond the third row', (
    tester,
  ) async {
    await pumpDock(tester, count: 19);
    expect(findAppCard('test.app.18'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isAppCardFocused(tester, 'test.app.6'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isAppCardFocused(tester, 'test.app.12'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    // Focus schedules the reveal after a frame; its ticker starts on the next
    // frame. Wait for the actual animation rather than sampling its first tick.
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(isAppCardFocused(tester, 'test.app.18'), isTrue);
    final scrollable = Scrollable.of(
      tester.element(findAppCard('test.app.18')),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    final rect = tester.getRect(findAppCard('test.app.18'));
    expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
    expect(rect.bottom, lessThanOrEqualTo(540.0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('second-row app launches and reorder can move vertically', (
    tester,
  ) async {
    final service = await pumpDock(tester, count: 12);
    final card = tester.widget<AppCard>(findAppCard('test.app.6'));
    card.onMove(AxisDirection.up);
    verify(service.reorderApplication(card.category, 6, 0)).called(1);
    verify(
      service.setPendingReorderFocus('test.app.6', card.category.id),
    ).called(1);
    await tester.tap(findAppCard('test.app.7'));
    await tester.pump(const Duration(milliseconds: 200));
    verify(service.launchApp(card.category.applications[7])).called(1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<AppsService> pumpDock(
  WidgetTester tester, {
  required int count,
  bool showNames = false,
  double iconScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final service = fixtures.mkAppService();
  final settings = fixtures.mkSettingsService();
  when(settings.showAppNamesBelowIcons).thenReturn(showNames);
  when(settings.favoriteIconScale).thenReturn(iconScale);
  when(settings.appHighlightAnimationEnabled).thenReturn(false);
  final apps = List.generate(
    count,
    (i) => App(
      packageName: 'test.app.$i',
      name: 'App $i',
      version: '1',
      hidden: false,
    ),
  );
  final category = Category.withApplications(
    name: 'Favorites',
    applications: apps,
  );
  when(service.categories).thenReturn([category]);
  when(service.launcherSections).thenReturn([category]);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: service),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<WallpaperService>.value(
          value: fixtures.mkWallpaperService(false),
        ),
        ChangeNotifierProvider<WatchNextService>.value(
          value: fixtures.mkWatchNextService(),
        ),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider(
          create: (_) => NetworkService(FLauncherChannel()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FLauncher(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  return service;
}
