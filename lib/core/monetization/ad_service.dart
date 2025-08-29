import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'monetization_models.dart';

// Stub implementations for Google Mobile Ads (enable in production)
class MobileAds {
  static MobileAds instance = MobileAds._();
  MobileAds._();

  Future<void> initialize() async {}
  Future<void> updateRequestConfiguration(RequestConfiguration config) async {}
}

class RequestConfiguration {
  final List<String> testDeviceIds;
  final TagForChildDirectedTreatment tagForChildDirectedTreatment;
  final TagForUnderAgeOfConsent tagForUnderAgeOfConsent;
  final MaxAdContentRating maxAdContentRating;

  RequestConfiguration({
    required this.testDeviceIds,
    required this.tagForChildDirectedTreatment,
    required this.tagForUnderAgeOfConsent,
    required this.maxAdContentRating,
  });
}

enum TagForChildDirectedTreatment { yes, no, unspecified }

enum TagForUnderAgeOfConsent { yes, no, unspecified }

enum MaxAdContentRating { g, pg, t, ma }

class AdSize {
  static const AdSize banner = AdSize._(320, 50);
  final int width;
  final int height;
  const AdSize._(this.width, this.height);
}

class AdRequest {
  const AdRequest();
}

class BannerAd {
  final String adUnitId;
  final AdSize size;
  final AdRequest request;
  final BannerAdListener listener;

  BannerAd({
    required this.adUnitId,
    required this.size,
    required this.request,
    required this.listener,
  });

  Future<void> load() async {}
  void dispose() {}
}

class InterstitialAd {
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {}

  Future<void> show() async {}
  void dispose() {}
  FullScreenContentCallback? fullScreenContentCallback;
}

class RewardedAd {
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {}

  Future<void> show({
    required Function(dynamic, RewardItem) onUserEarnedReward,
  }) async {}
  void dispose() {}
  FullScreenContentCallback? fullScreenContentCallback;
}

class NativeAd {
  void dispose() {}
}

class BannerAdListener {
  final Function(dynamic)? onAdLoaded;
  final Function(dynamic, LoadAdError)? onAdFailedToLoad;
  final Function(dynamic)? onAdOpened;
  final Function(dynamic)? onAdClicked;

  BannerAdListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdOpened,
    this.onAdClicked,
  });
}

class InterstitialAdLoadCallback {
  final Function(InterstitialAd)? onAdLoaded;
  final Function(LoadAdError)? onAdFailedToLoad;

  InterstitialAdLoadCallback({this.onAdLoaded, this.onAdFailedToLoad});
}

class RewardedAdLoadCallback {
  final Function(RewardedAd)? onAdLoaded;
  final Function(LoadAdError)? onAdFailedToLoad;

  RewardedAdLoadCallback({this.onAdLoaded, this.onAdFailedToLoad});
}

class FullScreenContentCallback {
  final Function(dynamic)? onAdShowedFullScreenContent;
  final Function(dynamic)? onAdDismissedFullScreenContent;
  final Function(dynamic, dynamic)? onAdFailedToShowFullScreenContent;
  final Function(dynamic)? onAdClicked;

  FullScreenContentCallback({
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
    this.onAdClicked,
  });
}

class LoadAdError {
  final int code;
  final String message;

  LoadAdError({required this.code, required this.message});
}

class RewardItem {
  final int amount;
  final String type;

  RewardItem({required this.amount, required this.type});
}

/// Ad service for managing Google AdMob advertisements
class AdService {
  static const String _adConfigKey = 'ad_configuration';
  static const String _adRevenueKey = 'ad_revenue_data';

  final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _adsEnabled = true;

  // Ad unit IDs (replace with your actual AdMob unit IDs)
  static const Map<String, Map<String, String>> _adUnitIds = {
    'android': {
      'banner': 'ca-app-pub-3940256099942544/6300978111', // Test ID
      'interstitial': 'ca-app-pub-3940256099942544/1033173712', // Test ID
      'rewarded': 'ca-app-pub-3940256099942544/5224354917', // Test ID
      'native': 'ca-app-pub-3940256099942544/2247696110', // Test ID
    },
    'ios': {
      'banner': 'ca-app-pub-3940256099942544/2934735716', // Test ID
      'interstitial': 'ca-app-pub-3940256099942544/4411468910', // Test ID
      'rewarded': 'ca-app-pub-3940256099942544/1712485313', // Test ID
      'native': 'ca-app-pub-3940256099942544/3986624511', // Test ID
    },
  };

  // Active ads
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Ad loading states
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isNativeLoaded = false;

  // Revenue tracking
  double _totalAdRevenue = 0.0;
  final Map<String, double> _revenueByAdType = {};

  AdService(this._prefs);

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      // Load ad configurations
      await _loadAdConfigurations();

      // Set up request configuration
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: kDebugMode ? ['your_test_device_id'] : [],
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.g,
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _isInitialized = true;

      if (kDebugMode) {
        print('AdMob initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AdMob: $e');
      }
    }
  }

  /// Load ad configurations
  Future<void> _loadAdConfigurations() async {
    try {
      final configString = _prefs.getString(_adConfigKey);
      if (configString != null) {
        final config = jsonDecode(configString) as Map<String, dynamic>;
        _adsEnabled = config['enabled'] as bool? ?? true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ad configuration: $e');
      }
    }
  }

  /// Get platform-specific ad unit ID
  String _getAdUnitId(AdPlacement placement) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final placementKey = placement.name;
    return _adUnitIds[platform]?[placementKey] ?? '';
  }

  /// Load banner ad
  Future<void> loadBannerAd({
    AdSize adSize = AdSize.banner,
    Function(BannerAd)? onAdLoaded,
    Function(BannerAd, LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized || !_adsEnabled) return;

    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _getAdUnitId(AdPlacement.banner),
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          _trackAdRevenue(AdPlacement.banner, 0.01); // Estimated revenue
          onAdLoaded?.call(ad as BannerAd);
          if (kDebugMode) {
            print('Banner ad loaded');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          onAdFailedToLoad?.call(ad as BannerAd, error);
          if (kDebugMode) {
            print('Banner ad failed to load: $error');
          }
        },
        onAdOpened: (ad) {
          _trackAdRevenue(AdPlacement.banner, 0.05);
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClicked: (ad) {
          _trackAdRevenue(AdPlacement.banner, 0.10);
          if (kDebugMode) {
            print('Banner ad clicked');
          }
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// Load interstitial ad
  Future<void> loadInterstitialAd({
    Function(InterstitialAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized || !_adsEnabled) return;

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;

    await InterstitialAd.load(
      adUnitId: _getAdUnitId(AdPlacement.interstitial),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          onAdLoaded?.call(ad);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _trackAdRevenue(AdPlacement.interstitial, 0.25);
              if (kDebugMode) {
                print('Interstitial ad showed full screen content');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialLoaded = false;
              _interstitialAd = null;
              // Preload next interstitial
              loadInterstitialAd();
              if (kDebugMode) {
                print('Interstitial ad dismissed');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialLoaded = false;
              _interstitialAd = null;
              if (kDebugMode) {
                print('Interstitial ad failed to show: $error');
              }
            },
            onAdClicked: (ad) {
              _trackAdRevenue(AdPlacement.interstitial, 0.50);
              if (kDebugMode) {
                print('Interstitial ad clicked');
              }
            },
          );

          if (kDebugMode) {
            print('Interstitial ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoaded = false;
          onAdFailedToLoad?.call(error);
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }

  /// Load rewarded ad
  Future<void> loadRewardedAd({
    Function(RewardedAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized || !_adsEnabled) return;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedLoaded = false;

    await RewardedAd.load(
      adUnitId: _getAdUnitId(AdPlacement.rewarded),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          onAdLoaded?.call(ad);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _trackAdRevenue(AdPlacement.rewarded, 0.50);
              if (kDebugMode) {
                print('Rewarded ad showed full screen content');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedLoaded = false;
              _rewardedAd = null;
              // Preload next rewarded ad
              loadRewardedAd();
              if (kDebugMode) {
                print('Rewarded ad dismissed');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedLoaded = false;
              _rewardedAd = null;
              if (kDebugMode) {
                print('Rewarded ad failed to show: $error');
              }
            },
            onAdClicked: (ad) {
              _trackAdRevenue(AdPlacement.rewarded, 1.00);
              if (kDebugMode) {
                print('Rewarded ad clicked');
              }
            },
          );

          if (kDebugMode) {
            print('Rewarded ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoaded = false;
          onAdFailedToLoad?.call(error);
          if (kDebugMode) {
            print('Rewarded ad failed to load: $error');
          }
        },
      ),
    );
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready to show');
      }
    }
  }

  /// Show rewarded ad with callback
  Future<void> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    Function()? onAdDismissed,
  }) async {
    if (_isRewardedLoaded && _rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _trackAdRevenue(AdPlacement.rewarded, 2.00); // Higher reward value
          onUserEarnedReward(reward);
          if (kDebugMode) {
            print('User earned reward: ${reward.amount} ${reward.type}');
          }
        },
      );
    } else {
      if (kDebugMode) {
        print('Rewarded ad not ready to show');
      }
    }
  }

  /// Check if ads should be shown (based on subscription status)
  Future<bool> shouldShowAds() async {
    // Check if user has premium subscription
    // This should integrate with your SubscriptionService
    try {
      // Placeholder - integrate with actual subscription service
      final isPremium = _prefs.getBool('is_premium_user') ?? false;
      return !isPremium && _adsEnabled;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking ad eligibility: $e');
      }
      return _adsEnabled;
    }
  }

  /// Track ad revenue
  void _trackAdRevenue(AdPlacement placement, double estimatedRevenue) {
    _totalAdRevenue += estimatedRevenue;
    _revenueByAdType[placement.name] =
        (_revenueByAdType[placement.name] ?? 0) + estimatedRevenue;

    _saveRevenueData();

    if (kDebugMode) {
      print(
        'Ad revenue tracked: \$${estimatedRevenue.toStringAsFixed(4)} for ${placement.name}',
      );
    }
  }

  /// Save revenue data
  Future<void> _saveRevenueData() async {
    final revenueData = {
      'totalRevenue': _totalAdRevenue,
      'revenueByType': _revenueByAdType,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(_adRevenueKey, jsonEncode(revenueData));
  }

  /// Get ad revenue analytics
  Future<Map<String, dynamic>> getAdRevenueAnalytics() async {
    try {
      final revenueString = _prefs.getString(_adRevenueKey);
      if (revenueString != null) {
        final data = jsonDecode(revenueString) as Map<String, dynamic>;
        return {
          'totalRevenue': data['totalRevenue'] as double? ?? 0.0,
          'revenueByType': Map<String, double>.from(
            data['revenueByType'] as Map? ?? {},
          ),
          'lastUpdated': data['lastUpdated'] as String?,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading revenue analytics: $e');
      }
    }

    return {
      'totalRevenue': 0.0,
      'revenueByType': <String, double>{},
      'lastUpdated': null,
    };
  }

  /// Enable/disable ads
  Future<void> setAdsEnabled(bool enabled) async {
    _adsEnabled = enabled;
    await _prefs.setBool('ads_enabled', enabled);

    if (!enabled) {
      disposeAllAds();
    }
  }

  /// Get banner ad widget
  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;

  /// Check ad loading states
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  bool get isRewardedLoaded => _isRewardedLoaded;
  bool get isNativeLoaded => _isNativeLoaded;

  /// Preload all ads
  Future<void> preloadAllAds() async {
    if (!await shouldShowAds()) return;

    await Future.wait([loadBannerAd(), loadInterstitialAd(), loadRewardedAd()]);
  }

  /// Dispose all ads
  void disposeAllAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();

    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _nativeAd = null;

    _isBannerLoaded = false;
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
    _isNativeLoaded = false;
  }

  /// Dispose service
  void dispose() {
    disposeAllAds();
  }
}

/// Riverpod providers for ad management
final adServiceProvider = Provider<AdService>((ref) {
  throw UnimplementedError('AdService must be overridden');
});

final shouldShowAdsProvider = FutureProvider<bool>((ref) async {
  final adService = ref.watch(adServiceProvider);
  return await adService.shouldShowAds();
});

final adRevenueAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final adService = ref.watch(adServiceProvider);
  return await adService.getAdRevenueAnalytics();
});
