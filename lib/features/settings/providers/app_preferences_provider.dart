import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferencesState>(
      AppPreferencesController.new,
    );

final preferredReadingDirectionProvider = Provider<ReadingDirectionPreference>(
  (ref) => ref.watch(appPreferencesProvider).readingDirection,
);

final autoDoublePageProvider = Provider<bool>(
  (ref) => ref.watch(appPreferencesProvider).autoDoublePage,
);

final activeLibraryServerIdProvider = Provider<int?>(
  (ref) => ref.watch(appPreferencesProvider).activeServerId,
);

final serverReadingDirectionsProvider =
    Provider<Map<int, ReadingDirectionPreference>>(
  (ref) => ref.watch(appPreferencesProvider).serverReadingDirections,
);

enum ReadingDirectionPreference { ltr, rtl }

class AppPreferencesState {
  const AppPreferencesState({
    this.themeMode = ThemeMode.system,
    this.readingDirection = ReadingDirectionPreference.ltr,
    this.autoDoublePage = false,
    this.cacheSizeMb = 500,
    this.activeServerId,
    this.serverReadingDirections = const <int, ReadingDirectionPreference>{},
  });

  final ThemeMode themeMode;
  final ReadingDirectionPreference readingDirection;
  final bool autoDoublePage;
  final int cacheSizeMb;
  final int? activeServerId;
  final Map<int, ReadingDirectionPreference> serverReadingDirections;

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    ReadingDirectionPreference? readingDirection,
    bool? autoDoublePage,
    int? cacheSizeMb,
    int? activeServerId,
    Map<int, ReadingDirectionPreference>? serverReadingDirections,
    bool clearActiveServerId = false,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      readingDirection: readingDirection ?? this.readingDirection,
      autoDoublePage: autoDoublePage ?? this.autoDoublePage,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      activeServerId: clearActiveServerId
          ? null
          : (activeServerId ?? this.activeServerId),
      serverReadingDirections:
          serverReadingDirections ?? this.serverReadingDirections,
    );
  }
}

class AppPreferencesController extends Notifier<AppPreferencesState> {
  @override
  AppPreferencesState build() {
    Future.microtask(_load);
    return const AppPreferencesState();
  }

  static const String _themeModeKey = 'prefs.theme_mode';
  static const String _readingDirectionKey = 'prefs.reading_direction';
  static const String _serverReadingDirectionsKey =
      'prefs.server_reading_directions';
  static const String _autoDoublePageKey = 'prefs.auto_double_page';
  static const String _cacheSizeMbKey = 'prefs.cache_size_mb';
  static const String _activeServerIdKey = 'prefs.active_server_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeRaw = prefs.getString(_themeModeKey);
    final directionRaw = prefs.getString(_readingDirectionKey);
    final serverDirectionsRaw =
      prefs.getString(_serverReadingDirectionsKey);
    final autoDoublePage = prefs.getBool(_autoDoublePageKey) ?? false;
    final cacheSizeMb = prefs.getInt(_cacheSizeMbKey) ?? 500;
    final activeServerId = prefs.getInt(_activeServerIdKey);

    state = AppPreferencesState(
      themeMode: _themeModeFromRaw(themeRaw),
      readingDirection: _readingDirectionFromRaw(directionRaw),
      serverReadingDirections: _decodeServerReadingDirections(
        serverDirectionsRaw,
      ),
      autoDoublePage: autoDoublePage,
      cacheSizeMb: cacheSizeMb,
      activeServerId: activeServerId,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setReadingDirection(ReadingDirectionPreference direction) async {
    state = state.copyWith(readingDirection: direction);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readingDirectionKey, direction.name);
  }

  Future<void> setCacheSizeMb(int sizeMb) async {
    state = state.copyWith(cacheSizeMb: sizeMb);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheSizeMbKey, sizeMb);
  }

  Future<void> setAutoDoublePage(bool enabled) async {
    state = state.copyWith(autoDoublePage: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDoublePageKey, enabled);
  }

  Future<void> setActiveServerId(int? serverId) async {
    state = state.copyWith(
      activeServerId: serverId,
      clearActiveServerId: serverId == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (serverId == null) {
      await prefs.remove(_activeServerIdKey);
      return;
    }
    await prefs.setInt(_activeServerIdKey, serverId);
  }

  Future<void> setServerReadingDirection(
    int serverId,
    ReadingDirectionPreference direction,
  ) async {
    final updated = Map<int, ReadingDirectionPreference>.from(
      state.serverReadingDirections,
    )..[serverId] = direction;

    state = state.copyWith(serverReadingDirections: updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _serverReadingDirectionsKey,
      _encodeServerReadingDirections(updated),
    );
  }

  ThemeMode _themeModeFromRaw(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  ReadingDirectionPreference _readingDirectionFromRaw(String? raw) {
    switch (raw) {
      case 'rtl':
        return ReadingDirectionPreference.rtl;
      case 'ltr':
      default:
        return ReadingDirectionPreference.ltr;
    }
  }

  String _encodeServerReadingDirections(
    Map<int, ReadingDirectionPreference> directions,
  ) {
    final encoded = <String, String>{
      for (final entry in directions.entries)
        entry.key.toString(): entry.value.name,
    };
    return jsonEncode(encoded);
  }

  Map<int, ReadingDirectionPreference> _decodeServerReadingDirections(
    String? raw,
  ) {
    if ((raw ?? '').trim().isEmpty) {
      return const <int, ReadingDirectionPreference>{};
    }

    try {
      final decoded = jsonDecode(raw!);
      if (decoded is! Map<String, dynamic>) {
        return const <int, ReadingDirectionPreference>{};
      }

      final result = <int, ReadingDirectionPreference>{};
      for (final entry in decoded.entries) {
        final key = int.tryParse(entry.key);
        if (key == null) {
          continue;
        }

        final value = _readingDirectionFromRaw(entry.value?.toString());
        result[key] = value;
      }
      return result;
    } catch (_) {
      return const <int, ReadingDirectionPreference>{};
    }
  }
}
