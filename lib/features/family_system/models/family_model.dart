/// User roles in the family system
enum UserRole { parent, student, teacher, admin }

/// User status for live tracking
enum UserStatus { online, offline, inQuiz, idle, busy }

/// Account types
enum AccountType { email, pin, qr }

/// Parent account model
class ParentAccount {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastActive;
  final List<String> studentIds; // IDs of linked students
  final Map<String, dynamic> preferences;
  final bool isVerified;
  final String? deviceId; // For device locking

  const ParentAccount({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.role = UserRole.parent,
    this.status = UserStatus.offline,
    required this.createdAt,
    required this.lastActive,
    this.studentIds = const [],
    this.preferences = const {},
    this.isVerified = false,
    this.deviceId,
  });

  ParentAccount copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastActive,
    List<String>? studentIds,
    Map<String, dynamic>? preferences,
    bool? isVerified,
    String? deviceId,
  }) {
    return ParentAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      studentIds: studentIds ?? this.studentIds,
      preferences: preferences ?? this.preferences,
      isVerified: isVerified ?? this.isVerified,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'studentIds': studentIds,
      'preferences': preferences,
      'isVerified': isVerified,
      'deviceId': deviceId,
    };
  }

  factory ParentAccount.fromJson(Map<String, dynamic> json) {
    return ParentAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      status: UserStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      studentIds: List<String>.from(json['studentIds'] as List),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map),
      isVerified: json['isVerified'] as bool? ?? false,
      deviceId: json['deviceId'] as String?,
    );
  }
}

/// Student profile model
class StudentProfile {
  final String id;
  final String name;
  final String? avatar;
  final int grade;
  final String parentId; // ID of the parent account
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, int> subjectProgress; // subject -> mastery level (0-100)
  final List<String> learningGoals;
  final Map<String, dynamic> preferences;
  final bool isActive;
  final String? deviceId; // For device locking
  final String? pin; // For PIN-based login
  final String? qrCode; // For QR-based login

  const StudentProfile({
    required this.id,
    required this.name,
    this.avatar,
    required this.grade,
    required this.parentId,
    this.role = UserRole.student,
    this.status = UserStatus.offline,
    required this.createdAt,
    required this.lastActive,
    this.subjectProgress = const {},
    this.learningGoals = const [],
    this.preferences = const {},
    this.isActive = true,
    this.deviceId,
    this.pin,
    this.qrCode,
  });

  StudentProfile copyWith({
    String? id,
    String? name,
    String? avatar,
    int? grade,
    String? parentId,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, int>? subjectProgress,
    List<String>? learningGoals,
    Map<String, dynamic>? preferences,
    bool? isActive,
    String? deviceId,
    String? pin,
    String? qrCode,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      grade: grade ?? this.grade,
      parentId: parentId ?? this.parentId,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      learningGoals: learningGoals ?? this.learningGoals,
      preferences: preferences ?? this.preferences,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      pin: pin ?? this.pin,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'grade': grade,
      'parentId': parentId,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'subjectProgress': subjectProgress,
      'learningGoals': learningGoals,
      'preferences': preferences,
      'isActive': isActive,
      'deviceId': deviceId,
      'pin': pin,
      'qrCode': qrCode,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      grade: json['grade'] as int,
      parentId: json['parentId'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      status: UserStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      subjectProgress: Map<String, int>.from(json['subjectProgress'] as Map),
      learningGoals: List<String>.from(json['learningGoals'] as List),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map),
      isActive: json['isActive'] as bool? ?? true,
      deviceId: json['deviceId'] as String?,
      pin: json['pin'] as String?,
      qrCode: json['qrCode'] as String?,
    );
  }
}

/// Family group model
class FamilyGroup {
  final String id;
  final String name;
  final String parentId;
  final List<String> studentIds;
  final DateTime createdAt;
  final Map<String, dynamic> settings;
  final bool isActive;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.parentId,
    this.studentIds = const [],
    required this.createdAt,
    this.settings = const {},
    this.isActive = true,
  });

  FamilyGroup copyWith({
    String? id,
    String? name,
    String? parentId,
    List<String>? studentIds,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
    bool? isActive,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
      'isActive': isActive,
    };
  }

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String,
      studentIds: List<String>.from(json['studentIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      settings: Map<String, dynamic>.from(json['settings'] as Map),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Device session model for device locking
class DeviceSession {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime loginTime;
  final DateTime? logoutTime;
  final bool isActive;
  final Map<String, dynamic> deviceInfo;

  const DeviceSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.loginTime,
    this.logoutTime,
    this.isActive = true,
    this.deviceInfo = const {},
  });

  DeviceSession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? platform,
    DateTime? loginTime,
    DateTime? logoutTime,
    bool? isActive,
    Map<String, dynamic>? deviceInfo,
  }) {
    return DeviceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      loginTime: loginTime ?? this.loginTime,
      logoutTime: logoutTime ?? this.logoutTime,
      isActive: isActive ?? this.isActive,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'loginTime': loginTime.toIso8601String(),
      'logoutTime': logoutTime?.toIso8601String(),
      'isActive': isActive,
      'deviceInfo': deviceInfo,
    };
  }

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      logoutTime: json['logoutTime'] != null
          ? DateTime.parse(json['logoutTime'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] as Map),
    );
  }
}

/// Family activity model for tracking family interactions
class FamilyActivity {
  final String id;
  final String familyId;
  final String userId;
  final String
  activityType; // 'login', 'logout', 'quiz_start', 'quiz_end', etc.
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const FamilyActivity({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.activityType,
    required this.timestamp,
    this.metadata = const {},
  });

  FamilyActivity copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? activityType,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return FamilyActivity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'userId': userId,
      'activityType': activityType,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory FamilyActivity.fromJson(Map<String, dynamic> json) {
    return FamilyActivity(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      userId: json['userId'] as String,
      activityType: json['activityType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}
