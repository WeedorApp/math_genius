/// Authentication suggestion model
class AuthSuggestion {
  final bool exists;
  final String suggestedAction;
  final String message;
  final List<String> signInMethods;

  const AuthSuggestion({
    required this.exists,
    required this.suggestedAction,
    required this.message,
    required this.signInMethods,
  });

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'suggestedAction': suggestedAction,
      'message': message,
      'signInMethods': signInMethods,
    };
  }

  factory AuthSuggestion.fromJson(Map<String, dynamic> json) {
    return AuthSuggestion(
      exists: json['exists'] as bool,
      suggestedAction: json['suggestedAction'] as String,
      message: json['message'] as String,
      signInMethods: List<String>.from(json['signInMethods'] as List),
    );
  }
}
