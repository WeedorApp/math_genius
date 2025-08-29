import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'monetization_models.dart';

/// Subscription service for managing premium subscriptions
class SubscriptionService {
  static const String _subscriptionKey = 'user_subscription';
  static const String _plansKey = 'subscription_plans';

  final SharedPreferences _prefs;
  final InAppPurchase _inAppPurchase;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Available subscription plans
  static final List<SubscriptionPlan> _defaultPlans = [
    SubscriptionPlan(
      id: 'premium_monthly',
      tier: SubscriptionTier.premium,
      name: 'Premium Monthly',
      description: 'Unlock all features with unlimited access',
      price: 9.99,
      currency: 'USD',
      durationDays: 30,
      features: [
        'Unlimited math problems',
        'Advanced AI tutoring',
        'Detailed progress reports',
        'Ad-free experience',
        'Priority support',
        'Custom learning paths',
      ],
      trialPeriod: '7 days free trial',
    ),
    SubscriptionPlan(
      id: 'premium_yearly',
      tier: SubscriptionTier.premium,
      name: 'Premium Yearly',
      description: 'Best value - Save 40% with annual billing',
      price: 59.99,
      currency: 'USD',
      durationDays: 365,
      features: [
        'Unlimited math problems',
        'Advanced AI tutoring',
        'Detailed progress reports',
        'Ad-free experience',
        'Priority support',
        'Custom learning paths',
        'Offline mode',
        'Export progress reports',
      ],
      isPopular: true,
      discount: 40.0,
    ),
    SubscriptionPlan(
      id: 'family_monthly',
      tier: SubscriptionTier.family,
      name: 'Family Monthly',
      description: 'Perfect for families with multiple children',
      price: 19.99,
      currency: 'USD',
      durationDays: 30,
      features: [
        'Up to 6 student profiles',
        'All Premium features',
        'Family dashboard',
        'Parent controls',
        'Shared progress tracking',
        'Multi-device support',
      ],
    ),
    SubscriptionPlan(
      id: 'family_yearly',
      tier: SubscriptionTier.family,
      name: 'Family Yearly',
      description: 'Ultimate family plan with maximum savings',
      price: 149.99,
      currency: 'USD',
      durationDays: 365,
      features: [
        'Up to 6 student profiles',
        'All Premium features',
        'Family dashboard',
        'Parent controls',
        'Shared progress tracking',
        'Multi-device support',
        'Priority family support',
        'Advanced analytics',
      ],
      discount: 37.5,
    ),
  ];

  SubscriptionService(this._prefs) : _inAppPurchase = InAppPurchase.instance {
    _initializePurchases();
  }

  /// Initialize in-app purchases
  void _initializePurchases() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdated,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
  }

  /// Handle purchase updates
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchases
        if (kDebugMode) {
          print('Purchase pending: ${purchaseDetails.productID}');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle purchase errors
        if (kDebugMode) {
          print('Purchase error: ${purchaseDetails.error}');
        }
        await _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchases
        await _handleSuccessfulPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      final plan = _defaultPlans.firstWhere(
        (p) => p.id == purchaseDetails.productID,
        orElse: () => _defaultPlans.first,
      );

      final subscription = UserSubscription(
        id:
            purchaseDetails.purchaseID ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: await _getCurrentUserId(),
        plan: plan,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: plan.durationDays)),
        autoRenew: true,
        paymentMethod: 'in_app_purchase',
        metadata: {
          'purchase_id': purchaseDetails.purchaseID,
          'transaction_date': purchaseDetails.transactionDate,
          'source': 'mobile_app',
        },
      );

      await _saveSubscription(subscription);

      if (kDebugMode) {
        print('Subscription activated: ${subscription.plan.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling successful purchase: $e');
      }
    }
  }

  /// Handle purchase error
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    // Log error for analytics
    if (kDebugMode) {
      print(
        'Purchase failed: ${purchaseDetails.productID} - ${purchaseDetails.error}',
      );
    }

    // You could send this to your analytics service
    // await AnalyticsService.trackPurchaseError(purchaseDetails);
  }

  /// Get current user ID (placeholder - integrate with your auth system)
  Future<String> _getCurrentUserId() async {
    // TODO: Integrate with your user management system
    return _prefs.getString('current_user_id') ?? 'anonymous';
  }

  /// Stream completion handler
  void _updateStreamOnDone() {
    if (kDebugMode) {
      print('Purchase stream completed');
    }
  }

  /// Stream error handler
  void _updateStreamOnError(dynamic error) {
    if (kDebugMode) {
      print('Purchase stream error: $error');
    }
  }

  /// Get available subscription plans
  List<SubscriptionPlan> getAvailablePlans() {
    try {
      final plansString = _prefs.getString(_plansKey);
      if (plansString != null) {
        final plansList = jsonDecode(plansString) as List;
        return plansList
            .map(
              (plan) => SubscriptionPlan.fromJson(plan as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading plans from storage: $e');
      }
    }
    return _defaultPlans;
  }

  /// Get current user subscription
  Future<UserSubscription?> getCurrentSubscription() async {
    try {
      final subscriptionString = _prefs.getString(_subscriptionKey);
      if (subscriptionString != null) {
        final subscription = UserSubscription.fromJson(
          jsonDecode(subscriptionString) as Map<String, dynamic>,
        );

        // Check if subscription is still valid
        if (subscription.isActive) {
          return subscription;
        } else {
          // Subscription expired, remove it
          await _removeSubscription();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subscription: $e');
      }
    }
    return null;
  }

  /// Check if user has active premium subscription
  Future<bool> isPremiumUser() async {
    final subscription = await getCurrentSubscription();
    return subscription?.isPremium ?? false;
  }

  /// Check if user has specific subscription tier
  Future<bool> hasSubscriptionTier(SubscriptionTier tier) async {
    final subscription = await getCurrentSubscription();
    return subscription?.plan.tier == tier;
  }

  /// Purchase a subscription plan
  Future<bool> purchaseSubscription(String planId) async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        if (kDebugMode) {
          print('In-app purchases not available');
        }
        return false;
      }

      // Get product details
      const Set<String> productIds = {
        'premium_monthly',
        'premium_yearly',
        'family_monthly',
        'family_yearly',
      };

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print('Products not found: ${response.notFoundIDs}');
        }
      }

      final productDetails = response.productDetails.firstWhere(
        (product) => product.id == planId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error purchasing subscription: $e');
      }
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring purchases: $e');
      }
    }
  }

  /// Cancel subscription (platform-specific)
  Future<bool> cancelSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription != null) {
        final updatedSubscription = subscription.copyWith(
          status: SubscriptionStatus.cancelled,
          autoRenew: false,
        );
        await _saveSubscription(updatedSubscription);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling subscription: $e');
      }
    }
    return false;
  }

  /// Get subscription status for display
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final subscription = await getCurrentSubscription();

    if (subscription == null) {
      return {
        'tier': 'Free',
        'status': 'No active subscription',
        'daysRemaining': 0,
        'canUpgrade': true,
        'features': ['Limited math problems', 'Basic features only'],
      };
    }

    return {
      'tier': subscription.plan.name,
      'status': subscription.status.name,
      'daysRemaining': subscription.daysRemaining,
      'autoRenew': subscription.autoRenew,
      'features': subscription.plan.features,
      'canUpgrade': subscription.plan.tier != SubscriptionTier.family,
    };
  }

  /// Save subscription to local storage
  Future<void> _saveSubscription(UserSubscription subscription) async {
    await _prefs.setString(_subscriptionKey, jsonEncode(subscription.toJson()));
  }

  /// Remove subscription from local storage
  Future<void> _removeSubscription() async {
    await _prefs.remove(_subscriptionKey);
  }

  /// Update subscription plans (for remote configuration)
  Future<void> updateSubscriptionPlans(List<SubscriptionPlan> plans) async {
    final plansJson = jsonEncode(plans.map((p) => p.toJson()).toList());
    await _prefs.setString(_plansKey, plansJson);
  }

  /// Check feature access based on subscription
  Future<bool> hasFeatureAccess(String featureId) async {
    final subscription = await getCurrentSubscription();

    if (subscription == null || !subscription.isActive) {
      // Free tier features
      return [
        'basic_math_problems',
        'limited_ai_hints',
        'basic_progress_tracking',
      ].contains(featureId);
    }

    // Premium/Family tier features
    switch (subscription.plan.tier) {
      case SubscriptionTier.premium:
        return [
          'unlimited_math_problems',
          'advanced_ai_tutoring',
          'detailed_progress_reports',
          'ad_free_experience',
          'priority_support',
          'custom_learning_paths',
          'offline_mode',
          'export_reports',
        ].contains(featureId);

      case SubscriptionTier.family:
        return [
          'unlimited_math_problems',
          'advanced_ai_tutoring',
          'detailed_progress_reports',
          'ad_free_experience',
          'priority_support',
          'custom_learning_paths',
          'offline_mode',
          'export_reports',
          'multiple_profiles',
          'family_dashboard',
          'parent_controls',
          'shared_progress',
          'multi_device',
        ].contains(featureId);

      case SubscriptionTier.school:
        return true; // School tier has access to all features

      default:
        return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription.cancel();
  }
}

/// Riverpod providers for subscription management
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  throw UnimplementedError('SubscriptionService must be overridden');
});

final currentSubscriptionProvider = FutureProvider<UserSubscription?>((
  ref,
) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.getCurrentSubscription();
});

final isPremiumUserProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.isPremiumUser();
});

final subscriptionPlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getAvailablePlans();
});

final subscriptionStatusProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.getSubscriptionStatus();
});
