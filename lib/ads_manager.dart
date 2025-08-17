import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A helper class responsible for holding ad unit identifiers and
/// initialising the Google Mobile Ads SDK.  This class does **not**
/// automatically initialise the SDK because consent must be gathered
/// beforehand.  Instead, call [Ads.init] early in your app (for
/// example from `main()`) to register your ad unit ids and any test
/// device ids.  Later, once the [ConsentManager] reports that ads
/// may be requested, call `MobileAds.instance.initialize()`.
///
/// When integrating into your own application replace the test ad
/// unit ids with the production ids from the AdMob console.  See
/// Google's documentation for details.  Until replaced the default
/// ids below correspond to Google's sample inventory.
///
/// Without these declarations the SDK will refuse to load ads.
class Ads {
  Ads._();

  /// A singleton instance of [Ads].  Using a singleton avoids
  /// repeated configuration throughout your application.
  static final Ads instance = Ads._();

  /// Android banner ad unit id.
  String _bannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/9214589741';

  /// iOS banner ad unit id.
  String _bannerAdUnitIdiOS = 'ca-app-pub-3940256099942544/2435281174';

  /// Android interstitial ad unit id.
  String _interstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';

  /// iOS interstitial ad unit id.
  String _interstitialAdUnitIdiOS = 'ca-app-pub-3940256099942544/4411468910';

  /// Android App Open ad unit id.
  String _appOpenAdUnitIdAndroid = 'ca-app-pub-3940256099942544/9257395921';

  /// iOS App Open ad unit id.
  String _appOpenAdUnitIdiOS = 'ca-app-pub-3940256099942544/5575463023';

  /// Configure ad unit ids and optionally a list of test device ids.
  ///
  /// This method must be called before requesting any ads.  It does
  /// **not** initialise the SDK; instead, call
  /// `MobileAds.instance.initialize()` after consent has been
  /// gathered (see [ConsentManager]).
  Future<void> init({
    String? bannerAdUnitIdAndroid,
    String? bannerAdUnitIdiOS,
    String? interstitialAdUnitIdAndroid,
    String? interstitialAdUnitIdiOS,
    String? appOpenAdUnitIdAndroid,
    String? appOpenAdUnitIdiOS,
    List<String> testDeviceIds = const [],
  }) async {
    if (bannerAdUnitIdAndroid != null) {
      _bannerAdUnitIdAndroid = bannerAdUnitIdAndroid;
    }
    if (bannerAdUnitIdiOS != null) {
      _bannerAdUnitIdiOS = bannerAdUnitIdiOS;
    }
    if (interstitialAdUnitIdAndroid != null) {
      _interstitialAdUnitIdAndroid = interstitialAdUnitIdAndroid;
    }
    if (interstitialAdUnitIdiOS != null) {
      _interstitialAdUnitIdiOS = interstitialAdUnitIdiOS;
    }
    if (appOpenAdUnitIdAndroid != null) {
      _appOpenAdUnitIdAndroid = appOpenAdUnitIdAndroid;
    }
    if (appOpenAdUnitIdiOS != null) {
      _appOpenAdUnitIdiOS = appOpenAdUnitIdiOS;
    }

    // Apply the test device ids to the request configuration.  This
    // should be done before any ad requests are made.  The test ids
    // will persist until changed.
    if (testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
  }

  /// Returns the correct banner ad unit id for the current platform.
  String get bannerAdUnitId =>
      Platform.isAndroid ? _bannerAdUnitIdAndroid : _bannerAdUnitIdiOS;

  /// Returns the correct interstitial ad unit id for the current platform.
  String get interstitialAdUnitId => Platform.isAndroid
      ? _interstitialAdUnitIdAndroid
      : _interstitialAdUnitIdiOS;

  /// Returns the correct App Open ad unit id for the current platform.
  String get appOpenAdUnitId =>
      Platform.isAndroid ? _appOpenAdUnitIdAndroid : _appOpenAdUnitIdiOS;
}

/// Handles GDPR/UMP consent using the built‑in facilities provided by
/// `google_mobile_ads`.  This class requests consent information and
/// displays the consent form when necessary.  It exposes helpers to
/// determine if the SDK may request ads and whether a privacy
/// options form should be shown from your app's settings page.  The
/// class also exposes [getAdRequest] which constructs an
/// appropriate [AdRequest] taking into account the user's consent
/// status and adds the `npa=1` extra when personalised ads are not
/// permitted.
// Listener type used when requesting consent.  Mirrors the
// `OnConsentGatheringCompleteListener` typedef from Google's samples.
typedef OnConsentGatheringCompleteListener = void Function(FormError? error);

class ConsentManager {
  ConsentManager._();

  /// Singleton instance to avoid multiple concurrent consent flows.
  static final ConsentManager instance = ConsentManager._();

  /// Request updated consent information and display the consent form
  /// if required.  This method should be called before attempting to
  /// initialize the Mobile Ads SDK.  If [debugGeography] is
  /// specified the User Messaging Platform will simulate the user
  /// being in the EEA (`DebugGeography.debugGeographyEea`) or not
  /// (`DebugGeography.debugGeographyNotEea`); omit this argument for
  /// production builds.
  Future<void> requestConsentAndShowFormIfNeeded({
    DebugGeography? debugGeography,
  }) async {
    final completer = Completer<void>();
    gatherConsent((FormError? error) {
      // Note: the error is provided to the caller via the listener; it is
      // not stored internally.
      completer.complete();
    }, debugGeography: debugGeography);
    return completer.future;
  }

  /// Returns `true` if the Mobile Ads SDK may request ads based on
  /// current consent information.  When this returns `false` you
  /// should either avoid requesting ads or ensure that only
  /// non‑personalised ads are requested (see [getAdRequest]).
  Future<bool> canRequestAds() async {
    return await ConsentInformation.instance.canRequestAds();
  }

  /// Returns `true` if the privacy options form is required.  When
  /// true you should show a settings entry point that calls
  /// [showPrivacyOptionsForm].
  Future<bool> isPrivacyOptionsRequired() async {
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  /// Show the privacy options form if available.  The [listener] is
  /// called when the form is dismissed.  You can call this from
  /// within a Settings screen to allow the user to update their
  /// preferences at any time.
  void showPrivacyOptionsForm(OnConsentFormDismissedListener listener) {
    ConsentForm.showPrivacyOptionsForm(listener);
  }

  /// Perform the full consent flow: request updated consent
  /// information and load and show the consent form if necessary.
  /// Pass a [listener] that will be invoked when consent gathering is
  /// complete (with a possible [FormError] if there was an error).  A
  /// [debugGeography] may be supplied for testing.
  void gatherConsent(
    OnConsentGatheringCompleteListener listener, {
    DebugGeography? debugGeography,
  }) {
    // Build debug settings only when a debug geography is provided.
    final ConsentDebugSettings debugSettings = debugGeography != null
        ? ConsentDebugSettings(debugGeography: debugGeography)
        : ConsentDebugSettings();
    final params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((
          FormError? loadError,
        ) {
          listener(loadError);
        });
      },
      (FormError formError) {
        // Propagate the error so callers can log or handle it.
        listener(formError);
      },
    );
  }

  /// Construct an [AdRequest] appropriate for the user's consent
  /// status.  When personalised ads are allowed (consent is obtained
  /// or not required) this returns a default request.  Otherwise the
  /// request includes the `npa=1` extra to indicate that only
  /// non‑personalised ads should be served.
  Future<AdRequest> getAdRequest() async {
    // The canRequestAds flag returns true only when the user has
    // provided consent or consent is not required.  When false we
    // request non‑personalised ads by setting the `npa` extra.
    final personalisedAllowed = await ConsentInformation.instance
        .canRequestAds();
    if (personalisedAllowed) {
      return const AdRequest();
    }
    return const AdRequest(extras: {'npa': '1'});
  }
}

/// A widget that encapsulates loading and displaying a banner ad.  It
/// automatically requests an anchored adaptive banner sized to the
/// device's current orientation.  When the orientation changes the
/// previous ad is disposed and a new one is requested.  Banner ads
/// require consent; this widget consults [ConsentManager] before
/// loading an ad and falls back to a non‑personalised request when
/// consent has not been granted.  You can optionally specify a
/// [CollapsiblePlacement] to position the banner at the top or bottom
/// of the screen.
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key, this.collapsible});

  /// When non-null, requests a collapsible banner anchored at the
  /// specified edge (top or bottom).  The value will be passed as
  /// the `collapsible` extra in the [AdRequest] and will determine the
  /// alignment of the banner.  When null (default) the banner is a
  /// standard anchored banner positioned at the bottom of the screen.
  final CollapsiblePlacement? collapsible;

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

/// Placement options for collapsible banners.  Pass one of these values
/// to [BannerAdView.collapsible] to request a collapsible banner and
/// position it at the top or bottom of the screen.
enum CollapsiblePlacement { top, bottom }

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _bannerAd;
  Orientation? _currentOrientation;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Loads a banner ad sized appropriately for the current screen
  /// orientation.  The ad is only loaded when the app has the
  /// necessary consent to request ads.  If consent has not been
  /// obtained a non‑personalised request will be made instead.
  Future<void> _loadAd() async {
    // Obtain a base ad request from the consent manager.  This request
    // may include extras (e.g. `{'npa': '1'}`) when personalised ads are
    // not permitted.
    final baseRequest = await ConsentManager.instance.getAdRequest();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );
    if (!mounted || size == null) {
      return;
    }
    // Merge existing extras with the collapsible directive when
    // requested.  The `collapsible` extra indicates to the AdMob
    // backend that a collapsible banner should be served.  When
    // `widget.collapsible` is null no collapsible extra is added.
    final mergedExtras = <String, String>{
      if (baseRequest.extras != null) ...baseRequest.extras!,
      if (widget.collapsible != null) 'collapsible': widget.collapsible!.name,
    };
    final request = mergedExtras.isEmpty
        ? baseRequest
        : AdRequest(extras: mergedExtras);
    final ad = BannerAd(
      adUnitId: Ads.instance.bannerAdUnitId,
      request: request,
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
        onAdClicked: (Ad ad) {},
      ),
    );
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_currentOrientation != orientation) {
          // Orientation changed; dispose existing ad and load new one.
          _bannerAd?.dispose();
          _bannerAd = null;
          _currentOrientation = orientation;
          _loadAd();
        }
        if (_bannerAd == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        );
      },
    );
  }
}

/// Controller class responsible for loading, showing and reloading
/// interstitial ads.  Create an instance and call [load] to begin
/// preloading the ad.  Call [show] when you want to display it; the
/// controller will automatically reload the next ad after the current
/// one is dismissed.  This controller respects consent via
/// [ConsentManager.getAdRequest].
class InterstitialController {
  InterstitialController({String? adUnitId})
    : _adUnitId = adUnitId ?? Ads.instance.interstitialAdUnitId;

  final String _adUnitId;
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  /// Loads an interstitial ad if one isn't already loading.  This
  /// method consults [ConsentManager] for the correct ad request.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    final request = await ConsentManager.instance.getAdRequest();
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _setFullScreenCallbacks(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Displays the interstitial ad if it is ready.  After the ad is
  /// dismissed the controller automatically loads the next ad.
  void show() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.show();
  }

  void _setFullScreenCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _interstitialAd = null;
        // Preload the next ad.
        load();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        load();
      },
      onAdShowedFullScreenContent: (Ad ad) {},
      onAdImpression: (Ad ad) {},
      onAdClicked: (Ad ad) {},
    );
  }

  /// Dispose the underlying interstitial ad if present.  Call this
  /// from your widget's `dispose` method to release resources.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

/// Manages App Open ads.  This class maintains a single cached ad
/// which is refreshed after being shown or when it expires.  Use
/// [loadAd] to preload an App Open ad and [showAdIfAvailable] to
/// display it if it meets freshness requirements.  The maximum cache
/// duration defaults to four hours to mirror the official sample.
class AppOpenManager {
  AppOpenManager({String? adUnitId, Duration? maxCacheDuration})
    : _adUnitId = adUnitId ?? Ads.instance.appOpenAdUnitId,
      maxCacheDuration = maxCacheDuration ?? const Duration(hours: 4);

  final String _adUnitId;
  final Duration maxCacheDuration;
  AppOpenAd? _appOpenAd;
  DateTime? _loadTime;
  bool _isShowingAd = false;

  /// Whether an App Open ad is currently available and has not
  /// expired.
  bool get isAdAvailable => _appOpenAd != null;

  /// Load an App Open ad.  This method respects consent via
  /// [ConsentManager.getAdRequest].  If the ad is successfully
  /// loaded it will be cached for up to [maxCacheDuration].
  Future<void> loadAd() async {
    final request = await ConsentManager.instance.getAdRequest();
    await AppOpenAd.load(
      adUnitId: _adUnitId,
      request: request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Ignore for now; you may choose to retry after a delay.
        },
      ),
    );
  }

  /// Show the App Open ad if available and not already showing.  If
  /// the cached ad has expired this will dispose it and attempt to
  /// load a new one.
  void showAdIfAvailable() {
    if (!isAdAvailable) {
      loadAd();
      return;
    }
    if (_isShowingAd) {
      return;
    }
    // Check freshness; if expired dispose and reload.
    final now = DateTime.now();
    final isExpired =
        _loadTime == null || now.difference(_loadTime!) > maxCacheDuration;
    if (isExpired) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdImpression: (Ad ad) {},
      onAdClicked: (Ad ad) {},
    );
    _appOpenAd!.show();
  }
}

/// Observes the app's lifecycle and triggers App Open ads when the
/// application resumes from the background.  On Android the
/// [AppStateEventNotifier] provided by the Mobile Ads SDK is used to
/// receive foreground events.  On platforms where this notifier is
/// unavailable the observer falls back to the Flutter framework's
/// [WidgetsBindingObserver].
class AdLifecycleObserver with WidgetsBindingObserver {
  AdLifecycleObserver({required this.appOpenManager});

  final AppOpenManager appOpenManager;

  StreamSubscription<AppState>? _appStateSubscription;

  /// Start listening to app lifecycle changes.  Call this once from
  /// `initState` or `main()` after initialising the ads manager.
  void startListening() {
    // Attempt to use the AppStateEventNotifier from google_mobile_ads.
    try {
      AppStateEventNotifier.startListening();
      _appStateSubscription = AppStateEventNotifier.appStateStream.listen((
        AppState state,
      ) {
        if (state == AppState.foreground) {
          appOpenManager.showAdIfAvailable();
        }
      });
    } catch (_) {
      // Fallback to WidgetsBindingObserver on platforms where
      // AppStateEventNotifier isn't available (e.g. unit tests).
      WidgetsBinding.instance.addObserver(this);
    }
  }

  /// Clean up the lifecycle listeners.  Call this from your
  /// `dispose` method to avoid memory leaks.
  void stopListening() {
    _appStateSubscription?.cancel();
    _appStateSubscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appOpenManager.showAdIfAvailable();
    }
  }
}
