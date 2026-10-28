import 'dart:math';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<App> appsOutsideFavorites(List<App> installed, List<App> favorites) {
  final favoritePackages = favorites.map((app) => app.packageName).toSet();
  final seen = <String>{};
  return installed.where((app) =>
      !app.hidden && !favoritePackages.contains(app.packageName) && seen.add(app.packageName)).toList();
}

/// A lazy, vertically scrolling grid. Its viewport sits below the fixed dock.
class AllAppsDrawer extends StatefulWidget {
  final List<App> applications;
  final bool hasFavorites;
  final VoidCallback onAppFocused;

  const AllAppsDrawer({
    super.key,
    required this.applications,
    required this.hasFavorites,
    required this.onAppFocused,
  });

  @override
  State<AllAppsDrawer> createState() => _AllAppsDrawerState();
}

class _AllAppsDrawerState extends State<AllAppsDrawer> {
  final ScrollController _controller = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final showNames = context.select<SettingsService, bool>((s) => s.showAppNamesBelowIcons);
    if (widget.applications.isEmpty) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(localizations.noOtherApps, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    // This category is presentation-only; installed apps retain their real
    // categories. Their context menu still offers Favourites, Hide and app info.
    final category = Category.withApplications(
      id: -1,
      name: localizations.allApps,
      applications: widget.applications,
      sort: CategorySort.alphabetical,
    );
    const columns = Category.ColumnsCount;
    const rowSpacing = 12.0;
    const headerHeight = 44.0;
    const bottomPadding = 16.0;

    return LayoutBuilder(builder: (context, constraints) {
      final contentWidth = constraints.maxWidth - 2 * kLauncherSectionHorizontalPadding;
      final aspectRatio = showNames
          ? appCardGridAspectRatio(contentWidth, columns)
          : kAppCardAspectRatio;
      final rowHeight = contentWidth / columns / aspectRatio;
      final rows = (widget.applications.length + columns - 1) ~/ columns;
      final totalHeight = headerHeight + rows * rowHeight + (rows - 1) * rowSpacing + bottomPadding;
      // Short lists sit towards the bottom; long lists use the entire panel
      // and scroll without imposing a fixed row count or item limit.
      final topSpace = max(0.0, constraints.maxHeight - totalHeight);

      return CustomScrollView(
        key: const Key('all_apps_scroll'),
        controller: _controller,
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topSpace)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: headerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(localizations.allApps, style: const TextStyle(color: Colors.white, fontSize: 20)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              left: kLauncherSectionHorizontalPadding,
              right: kLauncherSectionHorizontalPadding,
              bottom: bottomPadding,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: aspectRatio,
                mainAxisSpacing: rowSpacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = widget.applications[index];
                  return Padding(
                    key: ValueKey(app.packageName),
                    padding: const EdgeInsets.symmetric(
                      horizontal: kAppCardHorizontalPadding,
                      vertical: kAppCardVerticalPadding,
                    ),
                    child: AppCard(
                      category: category,
                      application: app,
                      autofocus: false,
                      handleUpNavigationToSettings: !widget.hasFavorites && index < columns,
                      enforceAspectRatio: false,
                      categoryActionsEnabled: false,
                      onFocused: widget.onAppFocused,
                      onMove: (_) {},
                      onMoveEnd: () {},
                    ),
                  );
                },
                childCount: widget.applications.length,
                findChildIndexCallback: (key) {
                  final index = widget.applications.indexWhere((app) => app.packageName == (key as ValueKey<String>).value);
                  return index < 0 ? null : index;
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}
