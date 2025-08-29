// Monetization models for Math Genius

/// Subscription tiers available in the app
enum SubscriptionTier { free, premium, family, school }

/// Subscription status
enum SubscriptionStatus { active, expired, cancelled, pending, trial }

/// Ad placement types
enum AdPlacement { banner, interstitial, rewarded, native }

/// Ad status
enum AdStatus { loaded, loading, failed, shown, clicked, closed }

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final double discount;
  final String? trialPeriod;

  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
    this.discount = 0.0,
    this.trialPeriod,
  });

  SubscriptionPlan copyWith({
    String? id,
    SubscriptionTier? tier,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? durationDays,
    List<String>? features,
    bool? isPopular,
    double? discount,
    String? trialPeriod,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      durationDays: durationDays ?? this.durationDays,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      discount: discount ?? this.discount,
      trialPeriod: trialPeriod ?? this.trialPeriod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier.name,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'durationDays': durationDays,
      'features': features,
      'isPopular': isPopular,
      'discount': discount,
      'trialPeriod': trialPeriod,
    };
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      durationDays: json['durationDays'] as int,
      features: List<String>.from(json['features'] as List),
      isPopular: json['isPopular'] as bool? ?? false,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      trialPeriod: json['trialPeriod'] as String?,
    );
  }
}

/// User subscription model
class UserSubscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime? trialEndDate;
  final Map<String, dynamic> metadata;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.paymentMethod,
    this.trialEndDate,
    this.metadata = const {},
  });

  bool get isActive =>
      status == SubscriptionStatus.active && DateTime.now().isBefore(endDate);

  bool get isTrialActive =>
      trialEndDate != null && DateTime.now().isBefore(trialEndDate!);

  bool get isPremium => plan.tier != SubscriptionTier.free;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  UserSubscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    String? paymentMethod,
    DateTime? trialEndDate,
    Map<String, dynamic>? metadata,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toJson(),
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'trialEndDate': trialEndDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      autoRenew: json['autoRenew'] as bool,
      paymentMethod: json['paymentMethod'] as String?,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Ad configuration model
class AdConfiguration {
  final String adUnitId;
  final AdPlacement placement;
  final bool isEnabled;
  final int refreshIntervalSeconds;
  final Map<String, dynamic> targeting;
  final List<String> keywords;
  final bool respectPrivacy;

  const AdConfiguration({
    required this.adUnitId,
    required this.placement,
    this.isEnabled = true,
    this.refreshIntervalSeconds = 30,
    this.targeting = const {},
    this.keywords = const [],
    this.respectPrivacy = true,
  });

  AdConfiguration copyWith({
    String? adUnitId,
    AdPlacement? placement,
    bool? isEnabled,
    int? refreshIntervalSeconds,
    Map<String, dynamic>? targeting,
    List<String>? keywords,
    bool? respectPrivacy,
  }) {
    return AdConfiguration(
      adUnitId: adUnitId ?? this.adUnitId,
      placement: placement ?? this.placement,
      isEnabled: isEnabled ?? this.isEnabled,
      refreshIntervalSeconds:
          refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      targeting: targeting ?? this.targeting,
      keywords: keywords ?? this.keywords,
      respectPrivacy: respectPrivacy ?? this.respectPrivacy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adUnitId': adUnitId,
      'placement': placement.name,
      'isEnabled': isEnabled,
      'refreshIntervalSeconds': refreshIntervalSeconds,
      'targeting': targeting,
      'keywords': keywords,
      'respectPrivacy': respectPrivacy,
    };
  }

  factory AdConfiguration.fromJson(Map<String, dynamic> json) {
    return AdConfiguration(
      adUnitId: json['adUnitId'] as String,
      placement: AdPlacement.values.firstWhere(
        (e) => e.name == json['placement'],
        orElse: () => AdPlacement.banner,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      refreshIntervalSeconds: json['refreshIntervalSeconds'] as int? ?? 30,
      targeting: Map<String, dynamic>.from(json['targeting'] as Map? ?? {}),
      keywords: List<String>.from(json['keywords'] as List? ?? []),
      respectPrivacy: json['respectPrivacy'] as bool? ?? true,
    );
  }
}

/// Revenue analytics model
class RevenueAnalytics {
  final String userId;
  final double totalRevenue;
  final double subscriptionRevenue;
  final double adRevenue;
  final int totalTransactions;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, double> revenueBySource;
  final Map<String, int> transactionsByType;

  const RevenueAnalytics({
    required this.userId,
    required this.totalRevenue,
    required this.subscriptionRevenue,
    required this.adRevenue,
    required this.totalTransactions,
    required this.periodStart,
    required this.periodEnd,
    required this.revenueBySource,
    required this.transactionsByType,
  });

  double get averageRevenuePerUser => totalRevenue;

  double get subscriptionPercentage =>
      totalRevenue > 0 ? (subscriptionRevenue / totalRevenue) * 100 : 0;

  double get adPercentage =>
      totalRevenue > 0 ? (adRevenue / totalRevenue) * 100 : 0;

  RevenueAnalytics copyWith({
    String? userId,
    double? totalRevenue,
    double? subscriptionRevenue,
    double? adRevenue,
    int? totalTransactions,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, double>? revenueBySource,
    Map<String, int>? transactionsByType,
  }) {
    return RevenueAnalytics(
      userId: userId ?? this.userId,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      subscriptionRevenue: subscriptionRevenue ?? this.subscriptionRevenue,
      adRevenue: adRevenue ?? this.adRevenue,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      revenueBySource: revenueBySource ?? this.revenueBySource,
      transactionsByType: transactionsByType ?? this.transactionsByType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalRevenue': totalRevenue,
      'subscriptionRevenue': subscriptionRevenue,
      'adRevenue': adRevenue,
      'totalTransactions': totalTransactions,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'revenueBySource': revenueBySource,
      'transactionsByType': transactionsByType,
    };
  }

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      userId: json['userId'] as String,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      subscriptionRevenue: (json['subscriptionRevenue'] as num).toDouble(),
      adRevenue: (json['adRevenue'] as num).toDouble(),
      totalTransactions: json['totalTransactions'] as int,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      revenueBySource: Map<String, double>.from(
        (json['revenueBySource'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      transactionsByType: Map<String, int>.from(
        (json['transactionsByType'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
    );
  }
}
