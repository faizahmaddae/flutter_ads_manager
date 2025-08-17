import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_manager.dart';

/// A minimal example demonstrating how to use the classes defined in
/// `ads_manager.dart`.  This app initialises ad unit ids, gathers
/// consent, initialises the Mobile Ads SDK, sets up an App Open
/// manager tied to the application lifecycle, displays a banner ad,
/// and provides a button to trigger an interstitial ad.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure your ad unit ids here.  Replace these with your own
  // values from the AdMob console when releasing your app.
  await Ads.instance.init(
    bannerAdUnitIdAndroid: 'ca-app-pub-3940256099942544/9214589741',
    bannerAdUnitIdiOS: 'ca-app-pub-3940256099942544/2435281174',
    interstitialAdUnitIdAndroid: 'ca-app-pub-3940256099942544/1033173712',
    interstitialAdUnitIdiOS: 'ca-app-pub-3940256099942544/4411468910',
    appOpenAdUnitIdAndroid: 'ca-app-pub-3940256099942544/9257395921',
    appOpenAdUnitIdiOS: 'ca-app-pub-3940256099942544/5575463023',
    // Add your device ids here during testing.  Example:
    // testDeviceIds: ['YOUR_DEVICE_ID'],
  );

  // Request consent and display the consent form if necessary.  The
  // method completes once consent gathering is finished.  You may
  // specify a DebugGeography to force the consent form to appear
  // during development (commented out below).  Do **not** set
  // debugGeography in production.
  await ConsentManager.instance.requestConsentAndShowFormIfNeeded(
    // debugGeography: DebugGeography.debugGeographyEea,
  );

  // Initialise the Mobile Ads SDK once consent has been obtained.  If
  // consent was denied the SDK will still initialise but only
  // non‑personalised ads will be served (controlled via
  // ConsentManager.getAdRequest()).
  await MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ads Manager Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppOpenManager _appOpenManager;
  late final AdLifecycleObserver _adLifecycleObserver;
  late final InterstitialController _interstitialController;

  @override
  void initState() {
    super.initState();
    // Create an AppOpenManager and preload the first app open ad.
    _appOpenManager = AppOpenManager();
    _appOpenManager.loadAd();
    // Tie the AppOpenManager to app lifecycle events.
    _adLifecycleObserver = AdLifecycleObserver(appOpenManager: _appOpenManager);
    _adLifecycleObserver.startListening();
    // Create an interstitial controller and preload the first ad.
    _interstitialController = InterstitialController();
    _interstitialController.load();
  }

  @override
  void dispose() {
    _interstitialController.dispose();
    _adLifecycleObserver.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ads Manager Demo')),
      bottomNavigationBar: const BannerAdView(),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content of the app goes here.  This example
            // displays a simple button that shows an interstitial ad.
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _interstitialController.show();
                },
                child: const Text('Show Interstitial'),
              ),
            ),
            // Banner ad anchored to the bottom of the screen.
            // const BannerAdView(collapsible: CollapsiblePlacement.bottom),
          ],
        ),
      ),
    );
  }
}
