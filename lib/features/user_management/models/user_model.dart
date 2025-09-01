import 'package:cloud_firestore/cloud_firestore.dart';

// Import GradeLevel from game models
import '../../game/models/game_model.dart';

/// User roles
enum UserRole { student, parent, teacher, admin, guest }

/// Account status
enum AccountStatus { active, inactive, suspended, pending, deleted }

/// Authentication methods
enum AuthMethod { email, phone, google, apple, facebook, anonymous }

/// Session status
enum SessionStatus { active, expired, terminated, idle }

/// User model
class User {
  final String id;
  final String email;
  final String? phone;
  final String displayName;
  final String? avatar;
  final UserRole role;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? familyId;
  final List<String> permissions;
  final Map<String, dynamic> profile;
  final GradeLevel? gradeLevel;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.displayName,
    this.avatar,
    this.role = UserRole.student,
    this.status = AccountStatus.active,
    required this.createdAt,
    this.lastLoginAt,
    this.lastActiveAt,
    this.preferences = const {},
    this.metadata = const {},
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.familyId,
    this.permissions = const [],
    this.profile = const {},
    this.gradeLevel,
  });

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? avatar,
    UserRole? role,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? familyId,
    List<String>? permissions,
    Map<String, dynamic>? profile,
    GradeLevel? gradeLevel,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      familyId: familyId ?? this.familyId,
      permissions: permissions ?? this.permissions,
      profile: profile ?? this.profile,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'avatar': avatar,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'preferences': preferences,
      'metadata': metadata,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'familyId': familyId,
      'permissions': permissions,
      'profile': profile,
      'gradeLevel': gradeLevel?.name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'avatar': avatar,
      'role': role.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
      'preferences': preferences,
      'metadata': metadata,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'familyId': familyId,
      'permissions': permissions,
      'profile': profile,
      'gradeLevel': gradeLevel?.name,
    };
  }

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      displayName: data['displayName'] as String,
      avatar: data['avatar'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.student,
      ),
      status: AccountStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AccountStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      familyId: data['familyId'] as String?,
      permissions: List<String>.from(data['permissions'] ?? []),
      profile: Map<String, dynamic>.from(data['profile'] ?? {}),
      gradeLevel: data['gradeLevel'] != null
          ? GradeLevel.values.firstWhere(
              (e) => e.name == data['gradeLevel'],
              orElse: () => GradeLevel.grade5,
            )
          : null,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      status: AccountStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : {},
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      familyId: json['familyId'] as String?,
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      profile: json['profile'] != null
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : {},
      gradeLevel: json['gradeLevel'] != null
          ? GradeLevel.values.firstWhere(
              (e) => e.name == json['gradeLevel'],
              orElse: () => GradeLevel.grade5,
            )
          : null,
    );
  }
}

/// User session model
class UserSession {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String userAgent;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final DateTime? expiresAt;
  final SessionStatus status;
  final Map<String, dynamic> metadata;

  const UserSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    this.lastActiveAt,
    this.expiresAt,
    this.status = SessionStatus.active,
    this.metadata = const {},
  });

  UserSession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? expiresAt,
    SessionStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
      'expiresAt': expiresAt,
      'status': status.name,
      'metadata': metadata,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      deviceType: json['deviceType'] as String,
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Authentication credentials model
class AuthCredentials {
  final String userId;
  final String email;
  final String? passwordHash;
  final AuthMethod authMethod;
  final String? providerId;
  final String? providerToken;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const AuthCredentials({
    required this.userId,
    required this.email,
    this.passwordHash,
    required this.authMethod,
    this.providerId,
    this.providerToken,
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  AuthCredentials copyWith({
    String? userId,
    String? email,
    String? passwordHash,
    AuthMethod? authMethod,
    String? providerId,
    String? providerToken,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AuthCredentials(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      authMethod: authMethod ?? this.authMethod,
      providerId: providerId ?? this.providerId,
      providerToken: providerToken ?? this.providerToken,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'passwordHash': passwordHash,
      'authMethod': authMethod.name,
      'providerId': providerId,
      'providerToken': providerToken,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      userId: json['userId'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String?,
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == json['authMethod'],
      ),
      providerId: json['providerId'] as String?,
      providerToken: json['providerToken'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// User profile model
class UserProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? country;
  final String? timezone;
  final String? language;
  final String? bio;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;

  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.dateOfBirth,
    this.gender,
    this.country,
    this.timezone,
    this.language,
    this.bio,
    this.preferences = const {},
    this.metadata = const {},
  });

  UserProfile copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? middleName,
    DateTime? dateOfBirth,
    String? gender,
    String? country,
    String? timezone,
    String? language,
    String? bio,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'country': country,
      'timezone': timezone,
      'language': language,
      'bio': bio,
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'country': country,
      'timezone': timezone,
      'language': language,
      'bio': bio,
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      country: json['country'] as String?,
      timezone: json['timezone'] as String?,
      language: json['language'] as String?,
      bio: json['bio'] as String?,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : {},
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}

/// Account settings model
class AccountSettings {
  final String userId;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool twoFactorEnabled;
  final String? twoFactorMethod;
  final bool privacyMode;
  final bool dataSharing;
  final String language;
  final String theme;
  final Map<String, dynamic> customSettings;
  final Map<String, dynamic> metadata;

  const AccountSettings({
    required this.userId,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.twoFactorEnabled = false,
    this.twoFactorMethod,
    this.privacyMode = false,
    this.dataSharing = false,
    this.language = 'en',
    this.theme = 'system',
    this.customSettings = const {},
    this.metadata = const {},
  });

  AccountSettings copyWith({
    String? userId,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? twoFactorEnabled,
    String? twoFactorMethod,
    bool? privacyMode,
    bool? dataSharing,
    String? language,
    String? theme,
    Map<String, dynamic>? customSettings,
    Map<String, dynamic>? metadata,
  }) {
    return AccountSettings(
      userId: userId ?? this.userId,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      privacyMode: privacyMode ?? this.privacyMode,
      dataSharing: dataSharing ?? this.dataSharing,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      customSettings: customSettings ?? this.customSettings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorMethod': twoFactorMethod,
      'privacyMode': privacyMode,
      'dataSharing': dataSharing,
      'language': language,
      'theme': theme,
      'customSettings': customSettings,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorMethod': twoFactorMethod,
      'privacyMode': privacyMode,
      'dataSharing': dataSharing,
      'language': language,
      'theme': theme,
      'customSettings': customSettings,
      'metadata': metadata,
    };
  }

  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      userId: json['userId'] as String,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      twoFactorMethod: json['twoFactorMethod'] as String?,
      privacyMode: json['privacyMode'] as bool? ?? false,
      dataSharing: json['dataSharing'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'system',
      customSettings: json['customSettings'] != null
          ? Map<String, dynamic>.from(json['customSettings'] as Map)
          : {},
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}
