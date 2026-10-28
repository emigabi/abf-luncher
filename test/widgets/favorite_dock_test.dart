import 'package:flauncher/flauncher.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/models/watch_next_item.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/all_apps_drawer.dart';
import 'package:flauncher/widgets/category_clean_row.dart';
import 'package:flauncher/widgets/watch_next_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../flauncher_test.dart' as fixtures;
import '../helpers.dart';

void main() {
  test('All Apps filters by package and excludes hidden apps and duplicates', () {
    App app(String package, {bool hidden = false}) => App(
      packageName: package, name: package, version: '1', hidden: hidden,
    );
    final installed = [app('favorite'), app('visible'), app('hidden', hidden: true), app('visible'), app('last')];
    expect(appsOutsideFavorites(installed, [app('favorite')]).map((a) => a.packageName), ['visible', 'last']);
    expect(appsOutsideFavorites([], []), isEmpty);
    expect(appsOutsideFavorites([app('favorite')], [app('favorite')]), isEmpty);
  });

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
      expect(first.top, lessThan(kToolbarHeight + 32));
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

  for (final count in [9, 27]) {
    testWidgets('favourites precede Watch Next and remote navigation works with $count apps', (
      tester,
    ) async {
      await pumpDock(tester, count: count, iconScale: 2 / 3, watchNextEnabled: true);
      expect(
        tester.getTopLeft(findAppCard('test.app.0')).dy,
        lessThan(kToolbarHeight + 32),
      );
      expect(
        tester.getBottomLeft(findAppCard('test.app.${count - 1}')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(WatchNextRow)).dy),
      );
      expect(isAppCardFocused(tester, 'test.app.0'), isTrue);
      final rows = count ~/ 9;
      for (var i = 0; i < rows; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      final fallbackIcon = find.byIcon(Icons.play_circle_outline);
      final watchFocus = tester.widgetList<Focus>(
        find.ancestor(of: fallbackIcon, matching: find.byType(Focus)),
      ).firstWhere((widget) => widget.focusNode != null).focusNode!;
      expect(watchFocus.hasFocus, isTrue);
      final watchRect = tester.getRect(
        find.ancestor(of: fallbackIcon, matching: find.byType(Card)),
      );
      expect(watchRect.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(watchRect.bottom, lessThanOrEqualTo(540.0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        List.generate(count, (i) => isAppCardFocused(tester, 'test.app.$i')).any((focused) => focused),
        isTrue,
      );
      expect(isSettingsIconFocused(tester), isFalse);
      for (var i = 0; i < rows; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(isSettingsIconFocused(tester), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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

  testWidgets('rapid Down presses reveal favourites below the viewport', (
    tester,
  ) async {
    // With the dock at the top, four rows can fit without scrolling. Use
    // nine rows so this checks genuine overflow rather than requiring an
    // unnecessary scroll when the selected card is already visible.
    const lastIndex = 48;
    await pumpDock(tester, count: lastIndex + 1);
    final lastCard = findAppCard('test.app.$lastIndex');
    expect(lastCard, findsOneWidget);
    expect(tester.getRect(lastCard).bottom, greaterThan(540.0));
    for (var row = 1; row <= lastIndex ~/ kFavoriteDockColumns; row++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(isAppCardFocused(tester, 'test.app.${row * kFavoriteDockColumns}'), isTrue);
    }
    // Focus schedules the reveal after a frame; its ticker starts on the next
    // frame. Wait for the actual animation rather than sampling its first tick.
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(isAppCardFocused(tester, 'test.app.$lastIndex'), isTrue);
    final scrollable = Scrollable.of(
      tester.element(lastCard),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    final rect = tester.getRect(lastCard);
    expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
    expect(rect.bottom, lessThanOrEqualTo(540.0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('All Apps hides Watch Next temporarily and excludes favourites', (tester) async {
    await pumpDock(tester, count: 9, iconScale: 2 / 3, watchNextEnabled: true, extraAppCount: 5);
    final context = tester.element(find.byType(FLauncher));
    final state = context.read<LauncherState>();
    final settings = context.read<SettingsService>();
    expect(state.allAppsExpanded, isFalse);
    expect(find.byType(AllAppsDrawer), findsNothing);
    expect(findAppCard('other.app.0'), findsNothing);
    expect(find.byType(WatchNextRow), findsOneWidget);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    expect(state.allAppsExpanded, isTrue);
    expect(find.byType(WatchNextRow), findsNothing);
    final drawer = tester.widget<AllAppsDrawer>(find.byType(AllAppsDrawer));
    expect(drawer.applications.map((app) => app.packageName),
        List.generate(5, (i) => 'other.app.$i'));
    expect(findAppCard('test.app.0'), findsOneWidget);
    expect(findAppCard('other.app.0'), findsOneWidget);
    expect(settings.showWatchNextSection, isTrue);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(AllAppsDrawer), findsNothing);
    expect(find.byType(WatchNextRow), findsOneWidget);
    expect(settings.showWatchNextSection, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('large All Apps grid scrolls independently of pinned favourites', (tester) async {
    await pumpDock(tester, count: 9, iconScale: 2 / 3, extraAppCount: 80);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    final originalTop = tester.getTopLeft(findAppCard('test.app.0')).dy;
    expect(findAppCard('other.app.79'), findsNothing);
    await tester.drag(find.byKey(const Key('all_apps_scroll')), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(findAppCard('other.app.79'), findsOneWidget);
    expect(tester.getTopLeft(findAppCard('test.app.0')).dy, closeTo(originalTop, 0.01));
    final lastRect = tester.getRect(findAppCard('other.app.79'));
    expect(lastRect.top, greaterThan(tester.getBottomLeft(findAppCard('test.app.0')).dy));
    expect(lastRect.bottom, lessThanOrEqualTo(540));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('remote reaches lazily built lower app rows without scrolling favourites', (tester) async {
    await pumpDock(tester, count: 9, iconScale: 2 / 3, extraAppCount: 80);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    final originalTop = tester.getTopLeft(findAppCard('test.app.0')).dy;
    final firstOther = tester.widget<InkWell>(
      find.descendant(of: findAppCard('other.app.0'), matching: find.byType(InkWell)).first,
    );
    firstOther.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var row = 1; row < 14; row++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'other.app.${row * 6}'), isTrue);
    }
    final lastRect = tester.getRect(findAppCard('other.app.78'));
    expect(lastRect.bottom, lessThanOrEqualTo(540));
    expect(lastRect.top, greaterThan(tester.getBottomLeft(findAppCard('test.app.0')).dy));
    expect(tester.getTopLeft(findAppCard('test.app.0')).dy, closeTo(originalTop, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty drawer closes without enabling disabled Watch Next', (tester) async {
    await pumpDock(tester, count: 0);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('No other apps to show'), findsOneWidget);
    final context = tester.element(find.byType(FLauncher));
    context.read<LauncherState>().handleBackNavigation(context);
    await tester.pumpAndSettle();
    expect(find.byType(AllAppsDrawer), findsNothing);
    expect(find.byType(WatchNextRow), findsNothing);
    expect(context.read<SettingsService>().showWatchNextSection, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('remote crosses between pinned favourites and the expanded grid; Back closes it', (tester) async {
    await pumpDock(tester, count: 9, iconScale: 2 / 3, watchNextEnabled: true, extraAppCount: 8);
    await tester.tap(find.byKey(const Key('all_apps_toggle')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(List.generate(9, (i) => isAppCardFocused(tester, 'test.app.$i')).any((focused) => focused), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(List.generate(8, (i) => isAppCardFocused(tester, 'other.app.$i')).any((focused) => focused), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(List.generate(9, (i) => isAppCardFocused(tester, 'test.app.$i')).any((focused) => focused), isTrue);
    final context = tester.element(find.byType(FLauncher));
    context.read<LauncherState>().handleBackNavigation(context);
    await tester.pumpAndSettle();
    expect(find.byType(AllAppsDrawer), findsNothing);
    expect(find.byType(WatchNextRow), findsOneWidget);
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
  bool watchNextEnabled = false,
  int extraAppCount = 0,
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
  when(settings.showWatchNextSection).thenReturn(watchNextEnabled);
  final watchNextService = fixtures.mkWatchNextService();
  if (watchNextEnabled) {
    when(watchNextService.hasPermission).thenReturn(true);
    when(watchNextService.hasVisibleSection).thenReturn(true);
    when(watchNextService.isLoading).thenReturn(false);
    when(watchNextService.items).thenReturn([
      WatchNextItem(id: 900, title: 'Continue watching', packageName: 'test.app.0'),
    ]);
    when(watchNextService.getPosterUriForItem(any)).thenReturn(null);
  }
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
  final installed = [
    ...apps,
    ...List.generate(extraAppCount, (i) => App(
      packageName: 'other.app.$i', name: 'Other App $i', version: '1', hidden: false,
    )),
  ];
  when(service.applications).thenReturn(installed);
  when(service.getApplication(any)).thenAnswer((call) {
    for (final app in installed) {
      if (app.packageName == call.positionalArguments.first) return app;
    }
    return null;
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: service),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<WallpaperService>.value(
          value: fixtures.mkWallpaperService(false),
        ),
        ChangeNotifierProvider<WatchNextService>.value(
          value: watchNextService,
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
