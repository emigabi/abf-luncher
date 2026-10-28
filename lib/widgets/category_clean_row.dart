/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/category_container_common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';

const kFavoriteDockColumns = 6;
const kFavoriteDockRowsPerPage = 3;

double normalizedFavoriteIconScale(double scale) => scale.isFinite
    ? scale.clamp(0.5, 1.0).toDouble()
    : DEFAULT_FAVORITE_ICON_SCALE;

int favoriteDockColumnsForScale(double scale) =>
    (kFavoriteDockColumns / normalizedFavoriteIconScale(scale)).floor();

int visibleFavoriteDockRows(
  int appCount, {
  int columns = kFavoriteDockColumns,
}) => min(kFavoriteDockRowsPerPage, (appCount + columns - 1) ~/ columns);

class CategoryCleanRow extends StatelessWidget {
  final Category category;
  final List<App> applications;

  final bool isFirstSection;
  final double scrollAlignment;
  final VoidCallback? onAppFocused;

  CategoryCleanRow({
    Key? key,
    required this.category,
    required this.applications,
    this.isFirstSection = false,
    this.scrollAlignment = 0.5,
    this.onAppFocused,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showAppNames = context.select<SettingsService, bool>(
      (s) => s.showAppNamesBelowIcons,
    );
    final iconScale = normalizedFavoriteIconScale(
      context.select<SettingsService, double>((s) => s.favoriteIconScale),
    );
    final columns = favoriteDockColumnsForScale(iconScale);
    Widget categoryContent;
    if (applications.isEmpty) {
      categoryContent = categoryContainerEmptyState(context);
    } else {
      categoryContent = LayoutBuilder(
        builder: (context, constraints) {
          final rowHeight =
              appCardRowExtentFromContentWidth(
                    constraints.maxWidth,
                    columnCount: kFavoriteDockColumns,
                  ) *
                  iconScale +
              (showAppNames ? kAppNameLabelHeight : 0);
          final slotWidth =
              constraints.maxWidth / kFavoriteDockColumns * iconScale;
          final rowCount = (applications.length + columns - 1) ~/ columns;
          final pageCount =
              (rowCount + kFavoriteDockRowsPerPage - 1) ~/
              kFavoriteDockRowsPerPage;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(pageCount, (page) {
              // Scroll up to three rows together, so focusing the first row
              // keeps the remaining visible rows on screen. More favourites
              // remain reachable by scrolling rather than being discarded.
              return Builder(
                builder: (pageContext) {
                  final firstRow = page * kFavoriteDockRowsPerPage;
                  final rowsInPage = min(
                    rowCount - firstRow,
                    kFavoriteDockRowsPerPage,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(rowsInPage, (pageRow) {
                      final row = firstRow + pageRow;
                      return SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: List.generate(columns, (column) {
                            final index = row * columns + column;
                            if (index >= applications.length) {
                              return const Expanded(child: SizedBox.shrink());
                            }
                            return Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: slotWidth,
                                  height: rowHeight,
                                  child: Padding(
                                    key: ValueKey(
                                      applications[index].packageName,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          kAppCardHorizontalPadding * iconScale,
                                      vertical:
                                          kAppCardVerticalPadding * iconScale,
                                    ),
                                    child: AppCard(
                                      category: category,
                                      application: applications[index],
                                      autofocus: index == 0,
                                      handleUpNavigationToSettings:
                                          isFirstSection && row == 0,
                                      scrollAlignment: scrollAlignment,
                                      enforceAspectRatio: false,
                                      ensureVisibleOnFocus: false,
                                      onFocused: () => _onFocused(pageContext),
                                      onMove: (direction) => _onMove(
                                        context,
                                        direction,
                                        index,
                                        columns,
                                      ),
                                      onMoveEnd: () => _onMoveEnd(context),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              );
            }),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [categoryContent],
    );
  }

  void _onFocused(BuildContext pageContext) {
    onAppFocused?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageContext.mounted) {
        Scrollable.ensureVisible(
          pageContext,
          alignment: scrollAlignment,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onMove(
    BuildContext context,
    AxisDirection direction,
    int index,
    int columns,
  ) {
    final column = index % columns;
    final row = index ~/ columns;
    final lastRow = (applications.length - 1) ~/ columns;
    int newIndex;

    if (direction == AxisDirection.right &&
        column < columns - 1 &&
        index < applications.length - 1) {
      newIndex = index + 1;
    } else if (direction == AxisDirection.left && column > 0) {
      newIndex = index - 1;
    } else if (direction == AxisDirection.up && row > 0) {
      newIndex = index - columns;
    } else if (direction == AxisDirection.down && row < lastRow) {
      newIndex = min(index + columns, applications.length - 1);
    } else {
      return;
    }

    final appsService = context.read<AppsService>();
    final movingApp = applications[index];
    final realOldIndex = category.applications.indexOf(movingApp);
    final realNewIndex = category.applications.indexOf(applications[newIndex]);
    if (realOldIndex >= 0 && realNewIndex >= 0) {
      appsService.reorderApplication(category, realOldIndex, realNewIndex);
      // Set pending focus so the app at the new position will request focus
      appsService.setPendingReorderFocus(movingApp.packageName, category.id);
    }
  }

  void _onMoveEnd(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.saveApplicationOrderInCategory(category);
  }
}
