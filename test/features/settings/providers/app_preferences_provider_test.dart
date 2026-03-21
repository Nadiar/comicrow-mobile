import 'package:comicrow/features/settings/providers/app_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores theme mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Trigger build and let the _load() microtask complete
    container.read(appPreferencesProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(appPreferencesProvider.notifier).setThemeMode(
      ThemeMode.dark,
    );

    expect(container.read(appPreferencesProvider).themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prefs.theme_mode'), 'dark');
  });

  test('persists reading direction and cache size', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(appPreferencesProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(appPreferencesProvider.notifier).setReadingDirection(
      ReadingDirectionPreference.rtl,
    );
    await container.read(appPreferencesProvider.notifier).setCacheSizeMb(1024);

    final state = container.read(appPreferencesProvider);
    expect(state.readingDirection, ReadingDirectionPreference.rtl);
    expect(state.cacheSizeMb, 1024);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prefs.reading_direction'), 'rtl');
    expect(prefs.getInt('prefs.cache_size_mb'), 1024);
  });

  test('persists auto double-page preference', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(appPreferencesProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(appPreferencesProvider.notifier).setAutoDoublePage(true);

    expect(container.read(appPreferencesProvider).autoDoublePage, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('prefs.auto_double_page'), isTrue);
  });
}
