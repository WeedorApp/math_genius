// Content models for Math Genius content management system

/// Content types available in the system
enum ContentType {
  mathProblem,
  lesson,
  tutorial,
  assessment,
  game,
  video,
  audio,
  image,
  document,
}

/// Content difficulty levels
enum ContentDifficulty { beginner, intermediate, advanced, expert }

/// Content status
enum ContentStatus { draft, review, approved, published, archived }

/// Content learning objectives (renamed to avoid conflicts)
enum ContentLearningObjective {
  counting,
  addition,
  subtraction,
  multiplication,
  division,
  fractions,
  decimals,
  geometry,
  algebra,
  statistics,
  probability,
  problemSolving,
}

/// Content metadata model
class ContentMetadata {
  final String id;
  final ContentType type;
  final String title;
  final String description;
  final ContentDifficulty difficulty;
  final List<ContentLearningObjective> objectives;
  final List<String> tags;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ContentStatus status;
  final Map<String, dynamic> customFields;

  const ContentMetadata({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.objectives,
    required this.tags,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.customFields = const {},
  });

  ContentMetadata copyWith({
    String? id,
    ContentType? type,
    String? title,
    String? description,
    ContentDifficulty? difficulty,
    List<ContentLearningObjective>? objectives,
    List<String>? tags,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    ContentStatus? status,
    Map<String, dynamic>? customFields,
  }) {
    return ContentMetadata(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      objectives: objectives ?? this.objectives,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      customFields: customFields ?? this.customFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'objectives': objectives.map((o) => o.name).toList(),
      'tags': tags,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'customFields': customFields,
    };
  }

  factory ContentMetadata.fromJson(Map<String, dynamic> json) {
    return ContentMetadata(
      id: json['id'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.mathProblem,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ContentDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ContentDifficulty.beginner,
      ),
      objectives:
          (json['objectives'] as List?)
              ?.map(
                (o) => ContentLearningObjective.values.firstWhere(
                  (e) => e.name == o,
                  orElse: () => ContentLearningObjective.counting,
                ),
              )
              .toList() ??
          [],
      tags: List<String>.from(json['tags'] as List? ?? []),
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: ContentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContentStatus.draft,
      ),
      customFields: Map<String, dynamic>.from(
        json['customFields'] as Map? ?? {},
      ),
    );
  }
}

/// Content version model for versioning support
class ContentVersion {
  final String id;
  final String contentId;
  final int versionNumber;
  final String versionName;
  final String changelog;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic> data;

  const ContentVersion({
    required this.id,
    required this.contentId,
    required this.versionNumber,
    required this.versionName,
    required this.changelog,
    required this.createdAt,
    required this.createdBy,
    required this.isActive,
    required this.data,
  });

  ContentVersion copyWith({
    String? id,
    String? contentId,
    int? versionNumber,
    String? versionName,
    String? changelog,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? data,
  }) {
    return ContentVersion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      versionNumber: versionNumber ?? this.versionNumber,
      versionName: versionName ?? this.versionName,
      changelog: changelog ?? this.changelog,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'versionNumber': versionNumber,
      'versionName': versionName,
      'changelog': changelog,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'data': data,
    };
  }

  factory ContentVersion.fromJson(Map<String, dynamic> json) {
    return ContentVersion(
      id: json['id'] as String,
      contentId: json['contentId'] as String,
      versionNumber: json['versionNumber'] as int,
      versionName: json['versionName'] as String,
      changelog: json['changelog'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      isActive: json['isActive'] as bool,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

/// Math problem content model
class MathProblemContent {
  final String id;
  final ContentMetadata metadata;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final List<String> hints;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic> interactiveElements;
  final List<String> prerequisites;
  final int estimatedTimeMinutes;
  final double points;

  const MathProblemContent({
    required this.id,
    required this.metadata,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.hints,
    this.imageUrl,
    this.audioUrl,
    this.interactiveElements = const {},
    this.prerequisites = const [],
    this.estimatedTimeMinutes = 2,
    this.points = 10.0,
  });

  MathProblemContent copyWith({
    String? id,
    ContentMetadata? metadata,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    List<String>? hints,
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? interactiveElements,
    List<String>? prerequisites,
    int? estimatedTimeMinutes,
    double? points,
  }) {
    return MathProblemContent(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      hints: hints ?? this.hints,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      interactiveElements: interactiveElements ?? this.interactiveElements,
      prerequisites: prerequisites ?? this.prerequisites,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metadata': metadata.toJson(),
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'hints': hints,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'interactiveElements': interactiveElements,
      'prerequisites': prerequisites,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'points': points,
    };
  }

  factory MathProblemContent.fromJson(Map<String, dynamic> json) {
    return MathProblemContent(
      id: json['id'] as String,
      metadata: ContentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
      hints: List<String>.from(json['hints'] as List),
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      interactiveElements: Map<String, dynamic>.from(
        json['interactiveElements'] as Map? ?? {},
      ),
      prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 2,
      points: (json['points'] as num?)?.toDouble() ?? 10.0,
    );
  }
}

/// Lesson content model
class LessonContent {
  final String id;
  final ContentMetadata metadata;
  final String title;
  final String introduction;
  final List<LessonSection> sections;
  final List<String> resources;
  final List<String> assessments;
  final int estimatedDurationMinutes;
  final List<String> prerequisites;
  final List<String> nextLessons;

  const LessonContent({
    required this.id,
    required this.metadata,
    required this.title,
    required this.introduction,
    required this.sections,
    required this.resources,
    required this.assessments,
    required this.estimatedDurationMinutes,
    this.prerequisites = const [],
    this.nextLessons = const [],
  });

  LessonContent copyWith({
    String? id,
    ContentMetadata? metadata,
    String? title,
    String? introduction,
    List<LessonSection>? sections,
    List<String>? resources,
    List<String>? assessments,
    int? estimatedDurationMinutes,
    List<String>? prerequisites,
    List<String>? nextLessons,
  }) {
    return LessonContent(
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
      title: title ?? this.title,
      introduction: introduction ?? this.introduction,
      sections: sections ?? this.sections,
      resources: resources ?? this.resources,
      assessments: assessments ?? this.assessments,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      prerequisites: prerequisites ?? this.prerequisites,
      nextLessons: nextLessons ?? this.nextLessons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metadata': metadata.toJson(),
      'title': title,
      'introduction': introduction,
      'sections': sections.map((s) => s.toJson()).toList(),
      'resources': resources,
      'assessments': assessments,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'prerequisites': prerequisites,
      'nextLessons': nextLessons,
    };
  }

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] as String,
      metadata: ContentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      title: json['title'] as String,
      introduction: json['introduction'] as String,
      sections: (json['sections'] as List)
          .map((s) => LessonSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      resources: List<String>.from(json['resources'] as List),
      assessments: List<String>.from(json['assessments'] as List),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
      nextLessons: List<String>.from(json['nextLessons'] as List? ?? []),
    );
  }
}

/// Lesson section model
class LessonSection {
  final String id;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final Map<String, dynamic> interactiveElements;
  final int order;

  const LessonSection({
    required this.id,
    required this.title,
    required this.content,
    required this.mediaUrls,
    required this.interactiveElements,
    required this.order,
  });

  LessonSection copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? mediaUrls,
    Map<String, dynamic>? interactiveElements,
    int? order,
  }) {
    return LessonSection(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      interactiveElements: interactiveElements ?? this.interactiveElements,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaUrls': mediaUrls,
      'interactiveElements': interactiveElements,
      'order': order,
    };
  }

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      mediaUrls: List<String>.from(json['mediaUrls'] as List),
      interactiveElements: Map<String, dynamic>.from(
        json['interactiveElements'] as Map? ?? {},
      ),
      order: json['order'] as int,
    );
  }
}

/// Content filter model
class ContentFilter {
  final ContentType? type;
  final ContentDifficulty? difficulty;
  final List<LearningObjective>? objectives;
  final List<String>? tags;
  final ContentStatus? status;
  final String? author;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? searchQuery;

  const ContentFilter({
    this.type,
    this.difficulty,
    this.objectives,
    this.tags,
    this.status,
    this.author,
    this.createdAfter,
    this.createdBefore,
    this.searchQuery,
  });

  ContentFilter copyWith({
    ContentType? type,
    ContentDifficulty? difficulty,
    List<ContentLearningObjective>? objectives,
    List<String>? tags,
    ContentStatus? status,
    String? author,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? searchQuery,
  }) {
    return ContentFilter(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      objectives: objectives ?? this.objectives,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      author: author ?? this.author,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type?.name,
      'difficulty': difficulty?.name,
      'objectives': objectives?.map((o) => o.name).toList(),
      'tags': tags,
      'status': status?.name,
      'author': author,
      'createdAfter': createdAfter?.toIso8601String(),
      'createdBefore': createdBefore?.toIso8601String(),
      'searchQuery': searchQuery,
    };
  }

  factory ContentFilter.fromJson(Map<String, dynamic> json) {
    return ContentFilter(
      type: json['type'] != null
          ? ContentType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => ContentType.mathProblem,
            )
          : null,
      difficulty: json['difficulty'] != null
          ? ContentDifficulty.values.firstWhere(
              (e) => e.name == json['difficulty'],
              orElse: () => ContentDifficulty.beginner,
            )
          : null,
      objectives: json['objectives'] != null
          ? (json['objectives'] as List)
                .map(
                  (o) => ContentLearningObjective.values.firstWhere(
                    (e) => e.name == o,
                    orElse: () => ContentLearningObjective.counting,
                  ),
                )
                .toList()
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      status: json['status'] != null
          ? ContentStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => ContentStatus.draft,
            )
          : null,
      author: json['author'] as String?,
      createdAfter: json['createdAfter'] != null
          ? DateTime.parse(json['createdAfter'] as String)
          : null,
      createdBefore: json['createdBefore'] != null
          ? DateTime.parse(json['createdBefore'] as String)
          : null,
      searchQuery: json['searchQuery'] as String?,
    );
  }
}

/// Content analytics model
class ContentAnalytics {
  final String contentId;
  final int viewCount;
  final int completionCount;
  final double averageRating;
  final int ratingCount;
  final Duration averageCompletionTime;
  final Map<String, int> difficultyFeedback;
  final List<String> popularTags;
  final DateTime lastAccessed;

  const ContentAnalytics({
    required this.contentId,
    required this.viewCount,
    required this.completionCount,
    required this.averageRating,
    required this.ratingCount,
    required this.averageCompletionTime,
    required this.difficultyFeedback,
    required this.popularTags,
    required this.lastAccessed,
  });

  double get completionRate =>
      viewCount > 0 ? (completionCount / viewCount) * 100 : 0;

  ContentAnalytics copyWith({
    String? contentId,
    int? viewCount,
    int? completionCount,
    double? averageRating,
    int? ratingCount,
    Duration? averageCompletionTime,
    Map<String, int>? difficultyFeedback,
    List<String>? popularTags,
    DateTime? lastAccessed,
  }) {
    return ContentAnalytics(
      contentId: contentId ?? this.contentId,
      viewCount: viewCount ?? this.viewCount,
      completionCount: completionCount ?? this.completionCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      averageCompletionTime:
          averageCompletionTime ?? this.averageCompletionTime,
      difficultyFeedback: difficultyFeedback ?? this.difficultyFeedback,
      popularTags: popularTags ?? this.popularTags,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'viewCount': viewCount,
      'completionCount': completionCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'averageCompletionTime': averageCompletionTime.inMilliseconds,
      'difficultyFeedback': difficultyFeedback,
      'popularTags': popularTags,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory ContentAnalytics.fromJson(Map<String, dynamic> json) {
    return ContentAnalytics(
      contentId: json['contentId'] as String,
      viewCount: json['viewCount'] as int,
      completionCount: json['completionCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      averageCompletionTime: Duration(
        milliseconds: json['averageCompletionTime'] as int,
      ),
      difficultyFeedback: Map<String, int>.from(
        json['difficultyFeedback'] as Map,
      ),
      popularTags: List<String>.from(json['popularTags'] as List),
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
    );
  }
}
