# Flutter Ads Manager

A clean, reusable ads management library for Flutter that integrates Google Mobile Ads (AdMob) with GDPR‑compliant consent handling. It supports adaptive **banner ads**, **collapsible## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

If you find this project helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs via [Issues](https://github.com/faizahmaddae/flutter_ads_manager/issues)
- 💡 Suggesting new features
- 📖 Improving documentation

## License

This project is based on Google's official Flutter AdMob samples and is provided as a reference implementation.  You are responsible for ensuring your app complies with Google's policies and local regulations.

---

**Repository:** https://github.com/faizahmaddae/flutter_ads_manager  
**Author:** [@faizahmaddae](https://github.com/faizahmaddae)nner ads**, **interstitial ads** and **app‑open ads** without any third‑party dependencies—only `google_mobile_ads` is used.Here’s the full contents of the `README.md` you can copy and paste directly:

````
# Flutter Ads Manager

A clean, reusable ads management library for Flutter that integrates Google Mobile Ads (AdMob) with GDPR‑compliant consent handling.  It supports adaptive **banner ads**, **collapsible banner ads**, **interstitial ads** and **app‑open ads** without any third‑party dependencies—only `google_mobile_ads` is used.

## Features

- ✅ **Unified API** – All ad logic is encapsulated in a single `ads_manager.dart` file so you can drop it into any Flutter project.
- 📜 **GDPR/UMP consent flow** – Uses Google’s built‑in User Messaging Platform (UMP) to collect consent from European users and automatically serves non‑personalised ads when required.
- 📐 **Adaptive banners** – Requests anchored adaptive banners that adjust their height based on screen width and orientation.
- 🔽 **Collapsible banners** – Request a collapsible banner by passing a `CollapsiblePlacement` (`top` or `bottom`); the directive is added via the `collapsible` extra in your `AdRequest`.
- 🚀 **Interstitials** – Preloads interstitial ads, shows them on demand and auto‑reloads after each display.
- 💤 **App‑open ads** – Loads one app‑open ad, checks its freshness (default 4 hours) and shows it when your app comes to the foreground.
- 🔄 **Lifecycle integration** – `AdLifecycleObserver` hooks into the app lifecycle to automatically show app‑open ads when appropriate.

## Installation

1. **Clone the repository:**
```bash
git clone https://github.com/faizahmaddae/flutter_ads_manager.git
cd flutter_ads_manager
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the project:**
```bash
flutter run
```

## Getting Started

### Prerequisites

- Flutter 3.0 or later
- The [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) plugin

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_mobile_ads: ^3.0.0
````

### Configure your AdMob App ID

Add your AdMob App ID to:

* **Android** – `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

* **iOS** – `ios/Runner/Info.plist`:

```plist
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### Import the Ads Manager

Copy `ads_manager.dart` into your project.  (You can rename it or split it if you prefer.)  Then initialise your ads early in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise your ad unit IDs and (optionally) test devices.
  await Ads.instance.init(
    bannerAdUnitIdAndroid: 'ca-app-pub-3940256099942544/9214589741',
    bannerAdUnitIdiOS:    'ca-app-pub-3940256099942544/2435281174',
    interstitialAdUnitIdAndroid: 'ca-app-pub-3940256099942544/1033173712',
    interstitialAdUnitIdiOS:    'ca-app-pub-3940256099942544/4411468910',
    appOpenAdUnitIdAndroid: 'ca-app-pub-3940256099942544/9257395921',
    appOpenAdUnitIdiOS:    'ca-app-pub-3940256099942544/5575463023',
    // Register test device IDs during development to avoid invalid traffic.
    testDeviceIds: ['YOUR_TEST_DEVICE_ID'],
  );

  // Request consent and show the UMP form if necessary.
  await ConsentManager.instance.requestConsentAndShowFormIfNeeded();

  // Initialise the Mobile Ads SDK.
  await MobileAds.instance.initialize();

  runApp(const MyApp());
}
```

### Display Ads

#### Banner Ads

Embed a banner anywhere in your widget tree.  By default it anchors to the bottom.  Pass `collapsible: CollapsiblePlacement.top` or `.bottom` to request a collapsible banner:

```dart
const BannerAdView(); // standard anchored banner at bottom

const BannerAdView(
  collapsible: CollapsiblePlacement.top,
); // collapsible banner pinned to the top
```

#### Interstitial Ads

Create an `InterstitialController`, preload the ad, and call `show()` when you want to display it.  The controller auto‑reloads after each dismissal:

```dart
late final InterstitialController _interstitialController;

@override
void initState() {
  super.initState();
  _interstitialController = InterstitialController();
  _interstitialController.load();
}

ElevatedButton(
  onPressed: () {
    _interstitialController.show();
  },
  child: const Text('Show Interstitial'),
);
```

Don’t forget to call `dispose()` on your controller when your widget is disposed.

#### App‑open Ads

Use `AppOpenManager` to manage app‑open ads.  Call `loadAd()` once at startup, and wire an `AdLifecycleObserver` to your app lifecycle:

```dart
late final AppOpenManager _appOpenManager;
late final AdLifecycleObserver _lifecycleObserver;

@override
void initState() {
  super.initState();
  _appOpenManager = AppOpenManager();
  _appOpenManager.loadAd();
  _lifecycleObserver = AdLifecycleObserver(appOpenManager: _appOpenManager);
  _lifecycleObserver.startListening();
}

@override
void dispose() {
  _lifecycleObserver.stopListening();
  super.dispose();
}
```

The manager caches one ad, discards it after 4 hours and shows it when the app returns to the foreground.

## Project Structure

```
flutter_ads_manager/
├── lib/
│   ├── main.dart              # Example usage and app entry point
│   └── ads_manager.dart       # Core ads management library
├── android/                   # Android-specific configuration
├── ios/                      # iOS-specific configuration
├── test/                     # Unit tests
├── pubspec.yaml              # Dependencies and project configuration
└── README.md                 # This documentation
```

## File Overview

* **`ads_manager.dart`** – Contains all classes:

    * `Ads` – stores and returns ad unit IDs, applies test devices.
    * `ConsentManager` – handles UMP consent flow and constructs consent‑aware `AdRequest`s.
    * `BannerAdView` – widget for adaptive banners with optional collapsible behaviour.
    * `InterstitialController` – loads, shows and reloads interstitial ads.
    * `AppOpenManager` – manages app‑open ads with freshness checks.
    * `AdLifecycleObserver` – listens to app lifecycle and triggers app‑open ads on resume.
* **`main.dart`** – Example usage demonstrating initialisation, consent gathering, lifecycle wiring and ad display.
* **`README.md`** – This document.

## Consent and Privacy

This project uses Google’s User Messaging Platform built into `google_mobile_ads`.  Users in the EEA are presented with a consent form before ads are requested.  If consent is denied or the status is unknown, the `AdRequest` is tagged with `npa=1` so that only non‑personalised ads are served.

When using debug geography for development, remember to remove it in production.  Always register test devices while testing to avoid invalid traffic.

## Best Practices

* **Avoid accidental clicks:** Keep banner ads away from interactive controls.  Don’t overlap ads on content.
* **Respect the user:** Don’t show interstitials on app launch; wait until there’s a natural break in your app flow.
* **Monitor revenue:** Use AdMob’s reporting to see which formats perform best.  Adjust frequency and placement accordingly.
* **Update your ad unit IDs:** Replace the sample IDs with your own production IDs before releasing your app.

## License

This project is based on Google’s official Flutter AdMob samples and is provided as a reference implementation.  You are responsible for ensuring your app complies with Google’s policies and local regulations.

```

You can copy and paste this into a `README.md` file in your project repository. Let me know if you'd like any further adjustments!
