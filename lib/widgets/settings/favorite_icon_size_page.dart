import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/category_clean_row.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteIconSizePage extends StatelessWidget {
  static const routeName = 'favorite_icon_size_panel';

  const FavoriteIconSizePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, service, _) {
        return Column(
          children: [
            SettingsPageHeader(title: localizations.favoriteIconSize),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(localizations.favoriteIconSizeHelp),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final scale in FAVORITE_ICON_SCALE_OPTIONS.reversed)
                    FocusableSettingsTile(
                      autofocus:
                          (scale - service.favoriteIconScale).abs() < 0.0001,
                      frameLeading: false,
                      leading: Icon(
                        (scale - service.favoriteIconScale).abs() < 0.0001
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(
                        localizations.favoriteIconSizeValue(
                          (scale * 100).round(),
                          favoriteDockColumnsForScale(scale),
                        ),
                      ),
                      onPressed: () => service.setFavoriteIconScale(scale),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
