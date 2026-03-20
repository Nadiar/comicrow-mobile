import '../../reader/providers/reader_provider.dart';

class ReadingModePreset {
  const ReadingModePreset({
    required this.serverId,
    required this.defaultReadingMode,
    required this.autoDoublePage,
  });

  final int serverId;
  final ReaderMode defaultReadingMode;
  final bool autoDoublePage;

  ReadingModePreset copyWith({
    ReaderMode? defaultReadingMode,
    bool? autoDoublePage,
  }) {
    return ReadingModePreset(
      serverId: serverId,
      defaultReadingMode: defaultReadingMode ?? this.defaultReadingMode,
      autoDoublePage: autoDoublePage ?? this.autoDoublePage,
    );
  }

  static ReaderMode readingModeFromRaw(String raw) {
    switch (raw) {
      case 'double':
        return ReaderMode.double;
      case 'vertical':
        return ReaderMode.vertical;
      case 'single':
      default:
        return ReaderMode.single;
    }
  }
}