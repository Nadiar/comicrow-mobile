# ComicRow

A comic reader app for [OPDS](https://opds.io/) servers, built with Flutter.

ComicRow connects to your self-hosted comic server (like [ComicOPDS](https://github.com/your-username/ComicOPDS)) and lets you browse and read comics on your phone or tablet — no syncing or downloading required.

## Why This Exists

There are no Android comic readers that support OPDS 2.0 with streaming (DiViNa manifests, PSE page streams). The only way to test a server implementation like [ComicOPDS](https://github.com/your-username/ComicOPDS) against a real client was to build one — so this project was written with AI assistance to fill that gap. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for details.

## Features

- **OPDS 1.2 and 2.0** catalog browsing with search
- **Streaming-first reading** — pages load on demand, no waiting for full downloads
  - DiViNa manifests (OPDS 2.0)
  - PSE page streams (OPDS 1.2)
  - Falls back to full archive download when streaming isn't available
- **Three reading modes** — single page, double-page spread, vertical scroll
- **Per-server presets** — default reading mode and auto double-page in landscape
- **Offline support** — download comics for reading without a connection
- **Read progress tracking** — picks up where you left off
- **RTL and LTR** reading direction

## Screenshots

<!-- Coming soon -->

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.32+
- An OPDS-compatible comic server

### Run

```bash
flutter pub get
flutter run
```

### Verify

```bash
flutter analyze
flutter test
```

## Project Structure

```text
lib/
├── core/           # OPDS clients, networking, storage, navigation
├── features/       # Feature modules (library, reader, settings, etc.)
│   ├── library/    # Catalog browsing and comic details
│   ├── reader/     # Comic reader with streaming support
│   ├── downloads/  # Download queue and offline reading
│   ├── servers/    # Server management
│   └── settings/   # App preferences
└── app.dart        # App entry point and theme
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — free for personal and non-commercial use.

## Acknowledgments

This project was built with AI assistance. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for details.
