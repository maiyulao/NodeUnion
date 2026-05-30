# NodeUnion

A cross-platform proxy client forked from [FlClash](https://github.com/chen08209/FlClash), tailored for proxy-provider (“airport”) operators. It keeps the full Clash.Meta (mihomo) stack while adding a remote brand config for the provider portal and optional ads.

**Languages:** [中文](README.zh.md) · English

Official Telegram: [t.me/NodeUnion](http://t.me/NodeUnion)

| Platform | Support |
|----------|---------|
| Android | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |
| iOS | Not supported yet |

## Features

- **Full proxy stack**: profile import/edit, nodes and policy groups, rules and DNS, connections and traffic stats (inherited from FlClash)
- **Built-in provider WebView**: loads the provider site from brand config; navigation can show a custom provider name
- **Remote brand config**: compile-time injection of encrypted config URLs and key; multi-CDN racing fetch with local cache
- **Optional AdMob**: remotely toggle banner, interstitial, native, and app-open ads plus cooldown rules via brand config
- **i18n**: Chinese, English, Japanese, Russian

## Relationship to FlClash

This project forks FlClash and adds a provider WebView, brand configuration, and ad modules on top of the core proxy stack. Credits and dependency notes are in the in-app About screen. When using or redistributing, comply with FlClash, Clash.Meta, and related dependency licenses.

## Quick start

### Requirements

- [Flutter](https://flutter.dev/) SDK **>= 3.8.0**
- [Go](https://go.dev/) (to build the Clash.Meta core)
- Native toolchains for your target platform (Android SDK, Visual Studio, Xcode for macOS desktop, etc.)

### Clone and dependencies

```bash
git clone https://github.com/maiyulao/NodeUnion.git
cd NodeUnion
flutter pub get
```

### Build the core

On first build or after updating the `core/` submodule, compile the native core:

```bash
dart run setup.dart android   # or linux / windows / macos
```

`setup.dart` builds Clash.Meta and creates/updates `env.json` (see below).

### Run locally

Without brand defines, proxy features still work, but the Airport tab shows a not-configured state:

```bash
flutter run
```

## Brand configuration (BrandConfig)

Brand config delivers the provider display name, portal URL, and optional ad settings. Values are injected at **compile time** via `--dart-define`; at runtime the app fetches **AES-GCM encrypted** JSON from remote URLs.

### 1. Prepare plain JSON

Copy the example and edit as needed:

```bash
cp brand.plain.json.example brand.plain.json
```

Plain JSON fields:

| Field | Type | Description |
|-------|------|-------------|
| `airportName` | string | Provider name shown in the UI (e.g. navigation) |
| `airportUrl` | string | Provider portal URL (`http` / `https`) |
| `ads` | object | Optional AdMob unit IDs and display policy; default `enabled: false` |

See `lib/models/brand_config_ads.dart` and `brand.plain.json.example` for `ads` subfields.

### 2. Encrypt and deploy

Encrypt with the bundled tool (**64 hex characters** = 32-byte AES-256 key):

```bash
dart run tools/encrypt_brand_config.dart \
  -i brand.plain.json \
  -k <your-64-hex-key> \
  -o brand.json
```

Upload `brand.json` to a CDN or static host. **Do not commit** `brand.plain.json`, `env.json`, or keys to Git (listed in `.gitignore`).

### 3. Local builds: env.json

Copy the env template:

```bash
cp env.json.example env.json
```

Edit `env.json`:

```json
{
  "APP_ENV": "pre",
  "BRAND_CONFIG_URLS": "https://cdn-a.example.com/brand.json,https://cdn-b.example.com/brand.json",
  "BRAND_CONFIG_KEY": "<64-hex-aes-key>"
}
```

- `BRAND_CONFIG_URLS`: comma-separated encrypted config URLs; the client requests them in parallel and uses the first successful response
- `BRAND_CONFIG_KEY`: the same hex key used when encrypting

Build with `dart-define-from-file`:

```bash
dart run setup.dart android
flutter build apk --release --dart-define-from-file=env.json
```

Or pass defines directly:

```bash
flutter build apk --release \
  --dart-define=BRAND_CONFIG_URLS=https://cdn.example.com/brand.json \
  --dart-define=BRAND_CONFIG_KEY=<64-hex-key>
```

### 4. Android release signing

```bash
cp android/key.properties.example android/key.properties
# Edit keystore path and passwords
flutter build apk --release --dart-define-from-file=env.json
```

Without `key.properties`, release builds fall back to the debug keystore — **local testing only**.

## Platform builds

After running `dart run setup.dart <platform>`:

| Platform | Example command |
|----------|-----------------|
| Android APK | `dart run setup.dart android` |
| Windows | `dart run setup.dart windows` |
| macOS | `dart run setup.dart macos` |
| Linux | `dart run setup.dart linux --arch <arm64 or amd64>` |

`setup.dart` uses [flutter_distributor](https://github.com/leanflutter/flutter_distributor) to produce artifacts (`apk`, `exe`, `deb`, `dmg`, etc.) and passes `dart-define` values from `env.json` into the Flutter build.

Core only, no app package:

```bash
dart run setup.dart android --out=core
```

## Project layout (excerpt)

```
├── core/                 # Clash.Meta (mihomo) submodule and Go build
├── lib/                  # Flutter app
│   ├── common/brand.dart # compile-time brand constants
│   ├── providers/        # brand config fetch and state
│   └── views/            # includes airport_webview
├── setup.dart            # core build and packaging entry
├── tools/
│   └── encrypt_brand_config.dart
├── brand.plain.json.example
└── env.json.example
```

## Security and compliance

- **Secrets and plain config**: `env.json`, `brand.json`, and `brand.plain.json` are gitignored; verify no real keys were committed before publishing
- **Ads**: enabling AdMob requires app and ad units in the Google AdMob console, plus the app ID in `AndroidManifest.xml` (see existing placeholders in the project)
- **License**: the Clash.Meta core is [GPL-3.0](https://github.com/MetaCubeX/mihomo/blob/main/LICENSE); redistribution and modifications must comply with GPL and FlClash upstream terms

## Acknowledgments

- [FlClash](https://github.com/chen08209/FlClash) — upstream UI and architecture
- [Clash.Meta / mihomo](https://github.com/MetaCubeX/mihomo) — proxy core

## License

This project is derived from FlClash. Follow the open-source licenses of FlClash, Clash.Meta (mihomo), and all dependencies. Perform your own compliance review before public release or commercial distribution.
