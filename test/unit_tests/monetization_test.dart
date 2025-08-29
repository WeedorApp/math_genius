import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_genius/core/monetization/barrel.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('Subscription Service Tests', () {
    late SubscriptionService subscriptionService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      subscriptionService = SubscriptionService(mockPrefs);
    });

    test('should return available subscription plans', () {
      final plans = subscriptionService.getAvailablePlans();
      
      expect(plans, isNotEmpty);
      expect(plans.length, equals(4));
      expect(plans.any((p) => p.tier == SubscriptionTier.premium), isTrue);
      expect(plans.any((p) => p.tier == SubscriptionTier.family), isTrue);
    });

    test('should identify premium features correctly', () async {
      // Mock no subscription
      when(mockPrefs.getString('user_subscription')).thenReturn(null);
      
      final hasFeature = await subscriptionService.hasFeatureAccess('unlimited_math_problems');
      expect(hasFeature, isFalse);
    });

    test('should handle subscription status correctly', () async {
      when(mockPrefs.getString('user_subscription')).thenReturn(null);
      
      final status = await subscriptionService.getSubscriptionStatus();
      expect(status['tier'], equals('Free'));
      expect(status['canUpgrade'], isTrue);
    });
  });

  group('Subscription Plan Tests', () {
    test('should create subscription plan with correct properties', () {
      final plan = SubscriptionPlan(
        id: 'test_plan',
        tier: SubscriptionTier.premium,
        name: 'Test Plan',
        description: 'Test Description',
        price: 9.99,
        currency: 'USD',
        durationDays: 30,
        features: ['feature1', 'feature2'],
      );

      expect(plan.id, equals('test_plan'));
      expect(plan.tier, equals(SubscriptionTier.premium));
      expect(plan.price, equals(9.99));
      expect(plan.features.length, equals(2));
    });

    test('should serialize and deserialize correctly', () {
      final originalPlan = SubscriptionPlan(
        id: 'test_plan',
        tier: SubscriptionTier.family,
        name: 'Test Plan',
        description: 'Test Description',
        price: 19.99,
        currency: 'USD',
        durationDays: 365,
        features: ['feature1', 'feature2', 'feature3'],
        isPopular: true,
        discount: 25.0,
      );

      final json = originalPlan.toJson();
      final deserializedPlan = SubscriptionPlan.fromJson(json);

      expect(deserializedPlan.id, equals(originalPlan.id));
      expect(deserializedPlan.tier, equals(originalPlan.tier));
      expect(deserializedPlan.price, equals(originalPlan.price));
      expect(deserializedPlan.isPopular, equals(originalPlan.isPopular));
      expect(deserializedPlan.discount, equals(originalPlan.discount));
    });
  });

  group('User Subscription Tests', () {
    test('should correctly identify active subscription', () {
      final plan = SubscriptionPlan(
        id: 'premium_monthly',
        tier: SubscriptionTier.premium,
        name: 'Premium Monthly',
        description: 'Premium plan',
        price: 9.99,
        currency: 'USD',
        durationDays: 30,
        features: ['unlimited_access'],
      );

      final subscription = UserSubscription(
        id: 'sub_123',
        userId: 'user_456',
        plan: plan,
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        autoRenew: true,
      );

      expect(subscription.isActive, isTrue);
      expect(subscription.isPremium, isTrue);
      expect(subscription.daysRemaining, equals(25));
    });

    test('should correctly identify expired subscription', () {
      final plan = SubscriptionPlan(
        id: 'premium_monthly',
        tier: SubscriptionTier.premium,
        name: 'Premium Monthly',
        description: 'Premium plan',
        price: 9.99,
        currency: 'USD',
        durationDays: 30,
        features: ['unlimited_access'],
      );

      final subscription = UserSubscription(
        id: 'sub_123',
        userId: 'user_456',
        plan: plan,
        status: SubscriptionStatus.expired,
        startDate: DateTime.now().subtract(const Duration(days: 35)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        autoRenew: false,
      );

      expect(subscription.isActive, isFalse);
      expect(subscription.isPremium, isTrue); // Plan is premium, but not active
      expect(subscription.daysRemaining, lessThan(0));
    });
  });

  group('Revenue Analytics Tests', () {
    test('should calculate revenue percentages correctly', () {
      final analytics = RevenueAnalytics(
        userId: 'user_123',
        totalRevenue: 100.0,
        subscriptionRevenue: 70.0,
        adRevenue: 30.0,
        totalTransactions: 10,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
        revenueBySource: {'subscriptions': 70.0, 'ads': 30.0},
        transactionsByType: {'subscription': 2, 'ad_click': 8},
      );

      expect(analytics.subscriptionPercentage, equals(70.0));
      expect(analytics.adPercentage, equals(30.0));
      expect(analytics.averageRevenuePerUser, equals(100.0));
    });

    test('should handle zero revenue correctly', () {
      final analytics = RevenueAnalytics(
        userId: 'user_123',
        totalRevenue: 0.0,
        subscriptionRevenue: 0.0,
        adRevenue: 0.0,
        totalTransactions: 0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
        revenueBySource: {},
        transactionsByType: {},
      );

      expect(analytics.subscriptionPercentage, equals(0.0));
      expect(analytics.adPercentage, equals(0.0));
      expect(analytics.averageRevenuePerUser, equals(0.0));
    });
  });
}
