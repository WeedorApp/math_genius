import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Supported locales for Math Genius
enum SupportedLocale { english, french, spanish, arabic }

/// Language service for Math Genius
class LanguageService {
  static const String _localeKey = 'selected_locale';

  final SharedPreferences _prefs;

  LanguageService(this._prefs);

  /// Get the current locale
  Future<Locale> getCurrentLocale() async {
    final localeString = _prefs.getString(_localeKey);
    if (localeString == null) return const Locale('en');

    return Locale(localeString);
  }

  /// Set the current locale
  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  /// Get supported locales
  List<Locale> getSupportedLocales() {
    return [
      const Locale('en'), // English
      const Locale('fr'), // French
      const Locale('es'), // Spanish
      const Locale('ar'), // Arabic
    ];
  }

  /// Get locale delegates
  List<LocalizationsDelegate<dynamic>> getLocalizationsDelegates() {
    return [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
  }

  /// Get locale resolution callback
  Locale? Function(Locale?, Iterable<Locale>) getLocaleResolutionCallback() {
    return (locale, supportedLocales) {
      // Check if the current device locale is supported
      for (final supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale?.languageCode) {
          return supportedLocale;
        }
      }

      // Default to English if not supported
      return const Locale('en');
    };
  }

  /// Get locale name
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  /// Get locale flag/icon
  String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'ar':
        return '🇸🇦';
      default:
        return '🇺🇸';
    }
  }

  /// Check if locale is RTL
  bool isRTL(Locale locale) {
    return locale.languageCode == 'ar';
  }

  /// Get text direction for locale
  TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Riverpod providers for language management
final languageServiceProvider = Provider<LanguageService>((ref) {
  throw UnimplementedError('LanguageService must be initialized');
});

final currentLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((
  ref,
) {
  return LocaleNotifier(ref.read(languageServiceProvider));
});

final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(currentLocaleProvider);
  final languageService = ref.read(languageServiceProvider);
  return languageService.getTextDirection(locale);
});

/// State notifier for locale management
class LocaleNotifier extends StateNotifier<Locale> {
  final LanguageService _service;

  LocaleNotifier(this._service) : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    state = await _service.getCurrentLocale();
  }

  Future<void> setLocale(Locale locale) async {
    await _service.setLocale(locale);
    state = locale;
  }
}

/// Localization strings for Math Genius
class MathGeniusLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'games': 'Games',
      'tutor': 'Tutor',
      'rewards': 'Rewards',
      'profile': 'Profile',

      // Common
      'start': 'Start',
      'continue': 'Continue',
      'pause': 'Pause',
      'resume': 'Resume',
      'stop': 'Stop',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'close': 'Close',
      'done': 'Done',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',

      // Math Operations
      'addition': 'Addition',
      'subtraction': 'Subtraction',
      'multiplication': 'Multiplication',
      'division': 'Division',
      'fractions': 'Fractions',
      'decimals': 'Decimals',
      'percentages': 'Percentages',
      'algebra': 'Algebra',
      'geometry': 'Geometry',
      'statistics': 'Statistics',

      // Game Modes
      'easy': 'Easy',
      'normal': 'Normal',
      'genius': 'Genius',
      'quantum': 'Quantum',

      // Rewards
      'stars': 'Stars',
      'badges': 'Badges',
      'achievements': 'Achievements',
      'level': 'Level',
      'experience': 'Experience',
      'points': 'Points',

      // User Roles
      'student': 'Student',
      'parent': 'Parent',
      'teacher': 'Teacher',
      'school': 'School',

      // Settings
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'sound': 'Sound',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'about': 'About',
      'help': 'Help',
      'feedback': 'Feedback',

      // Messages
      'welcome_message': 'Welcome to Math Genius!',
      'congratulations': 'Congratulations!',
      'great_job': 'Great job!',
      'keep_going': 'Keep going!',
      'try_again': 'Try again!',
      'not_quite_right': 'Not quite right.',
      'excellent': 'Excellent!',
      'amazing': 'Amazing!',
      'perfect': 'Perfect!',

      // Errors
      'network_error': 'Network error. Please check your connection.',
      'server_error': 'Server error. Please try again later.',
      'permission_denied': 'Permission denied.',
      'invalid_input': 'Invalid input.',
      'file_not_found': 'File not found.',
      'timeout': 'Request timeout.',

      // Questions
      'what_is': 'What is {expression}?',
      'solve_for_x': 'Solve for x: {equation}',
      'find_the_area': 'Find the area of {shape}.',
      'calculate_percentage': 'Calculate {percentage}% of {number}.',
      'simplify_fraction': 'Simplify the fraction {fraction}.',

      // Hints
      'hint_addition': 'Add the numbers together.',
      'hint_subtraction': 'Subtract the second number from the first.',
      'hint_multiplication': 'Multiply the numbers.',
      'hint_division': 'Divide the first number by the second.',
      'hint_fractions': 'Find a common denominator.',
      'hint_decimals': 'Line up the decimal points.',
      'hint_percentages': 'Convert percentage to decimal and multiply.',
      'hint_algebra': 'Isolate the variable on one side.',
      'hint_geometry': 'Use the appropriate formula.',
      'hint_statistics': 'Find the mean, median, or mode.',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'games': 'Jeux',
      'tutor': 'Tuteur',
      'rewards': 'Récompenses',
      'profile': 'Profil',

      // Common
      'start': 'Commencer',
      'continue': 'Continuer',
      'pause': 'Pause',
      'resume': 'Reprendre',
      'stop': 'Arrêter',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Sauvegarder',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'back': 'Retour',
      'next': 'Suivant',
      'previous': 'Précédent',
      'close': 'Fermer',
      'done': 'Terminé',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'warning': 'Avertissement',
      'info': 'Information',

      // Math Operations
      'addition': 'Addition',
      'subtraction': 'Soustraction',
      'multiplication': 'Multiplication',
      'division': 'Division',
      'fractions': 'Fractions',
      'decimals': 'Décimaux',
      'percentages': 'Pourcentages',
      'algebra': 'Algèbre',
      'geometry': 'Géométrie',
      'statistics': 'Statistiques',

      // Game Modes
      'easy': 'Facile',
      'normal': 'Normal',
      'genius': 'Génie',
      'quantum': 'Quantique',

      // Rewards
      'stars': 'Étoiles',
      'badges': 'Badges',
      'achievements': 'Réalisations',
      'level': 'Niveau',
      'experience': 'Expérience',
      'points': 'Points',

      // User Roles
      'student': 'Étudiant',
      'parent': 'Parent',
      'teacher': 'Enseignant',
      'school': 'École',

      // Settings
      'settings': 'Paramètres',
      'theme': 'Thème',
      'language': 'Langue',
      'sound': 'Son',
      'notifications': 'Notifications',
      'privacy': 'Confidentialité',
      'about': 'À propos',
      'help': 'Aide',
      'feedback': 'Commentaires',

      // Messages
      'welcome_message': 'Bienvenue dans Math Genius !',
      'congratulations': 'Félicitations !',
      'great_job': 'Bon travail !',
      'keep_going': 'Continuez !',
      'try_again': 'Essayez encore !',
      'not_quite_right': 'Pas tout à fait juste.',
      'excellent': 'Excellent !',
      'amazing': 'Incroyable !',
      'perfect': 'Parfait !',

      // Errors
      'network_error': 'Erreur réseau. Vérifiez votre connexion.',
      'server_error': 'Erreur serveur. Réessayez plus tard.',
      'permission_denied': 'Permission refusée.',
      'invalid_input': 'Entrée invalide.',
      'file_not_found': 'Fichier non trouvé.',
      'timeout': 'Délai d\'attente dépassé.',

      // Questions
      'what_is': 'Qu\'est-ce que {expression} ?',
      'solve_for_x': 'Résolvez pour x : {equation}',
      'find_the_area': 'Trouvez l\'aire de {shape}.',
      'calculate_percentage': 'Calculez {percentage}% de {number}.',
      'simplify_fraction': 'Simplifiez la fraction {fraction}.',

      // Hints
      'hint_addition': 'Additionnez les nombres.',
      'hint_subtraction': 'Soustrayez le deuxième nombre du premier.',
      'hint_multiplication': 'Multipliez les nombres.',
      'hint_division': 'Divisez le premier nombre par le deuxième.',
      'hint_fractions': 'Trouvez un dénominateur commun.',
      'hint_decimals': 'Alignez les points décimaux.',
      'hint_percentages':
          'Convertissez le pourcentage en décimal et multipliez.',
      'hint_algebra': 'Isolez la variable d\'un côté.',
      'hint_geometry': 'Utilisez la formule appropriée.',
      'hint_statistics': 'Trouvez la moyenne, la médiane ou le mode.',
    },
    'es': {
      // Navigation
      'home': 'Inicio',
      'games': 'Juegos',
      'tutor': 'Tutor',
      'rewards': 'Recompensas',
      'profile': 'Perfil',

      // Common
      'start': 'Comenzar',
      'continue': 'Continuar',
      'pause': 'Pausa',
      'resume': 'Reanudar',
      'stop': 'Detener',
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'close': 'Cerrar',
      'done': 'Hecho',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'warning': 'Advertencia',
      'info': 'Información',

      // Math Operations
      'addition': 'Suma',
      'subtraction': 'Resta',
      'multiplication': 'Multiplicación',
      'division': 'División',
      'fractions': 'Fracciones',
      'decimals': 'Decimales',
      'percentages': 'Porcentajes',
      'algebra': 'Álgebra',
      'geometry': 'Geometría',
      'statistics': 'Estadísticas',

      // Game Modes
      'easy': 'Fácil',
      'normal': 'Normal',
      'genius': 'Genio',
      'quantum': 'Cuántico',

      // Rewards
      'stars': 'Estrellas',
      'badges': 'Insignias',
      'achievements': 'Logros',
      'level': 'Nivel',
      'experience': 'Experiencia',
      'points': 'Puntos',

      // User Roles
      'student': 'Estudiante',
      'parent': 'Padre',
      'teacher': 'Maestro',
      'school': 'Escuela',

      // Settings
      'settings': 'Configuración',
      'theme': 'Tema',
      'language': 'Idioma',
      'sound': 'Sonido',
      'notifications': 'Notificaciones',
      'privacy': 'Privacidad',
      'about': 'Acerca de',
      'help': 'Ayuda',
      'feedback': 'Comentarios',

      // Messages
      'welcome_message': '¡Bienvenido a Math Genius!',
      'congratulations': '¡Felicitaciones!',
      'great_job': '¡Buen trabajo!',
      'keep_going': '¡Sigue así!',
      'try_again': '¡Inténtalo de nuevo!',
      'not_quite_right': 'No está del todo bien.',
      'excellent': '¡Excelente!',
      'amazing': '¡Increíble!',
      'perfect': '¡Perfecto!',

      // Errors
      'network_error': 'Error de red. Verifica tu conexión.',
      'server_error': 'Error del servidor. Inténtalo más tarde.',
      'permission_denied': 'Permiso denegado.',
      'invalid_input': 'Entrada inválida.',
      'file_not_found': 'Archivo no encontrado.',
      'timeout': 'Tiempo de espera agotado.',

      // Questions
      'what_is': '¿Qué es {expression}?',
      'solve_for_x': 'Resuelve para x: {equation}',
      'find_the_area': 'Encuentra el área de {shape}.',
      'calculate_percentage': 'Calcula {percentage}% de {number}.',
      'simplify_fraction': 'Simplifica la fracción {fraction}.',

      // Hints
      'hint_addition': 'Suma los números.',
      'hint_subtraction': 'Resta el segundo número del primero.',
      'hint_multiplication': 'Multiplica los números.',
      'hint_division': 'Divide el primer número por el segundo.',
      'hint_fractions': 'Encuentra un denominador común.',
      'hint_decimals': 'Alinea los puntos decimales.',
      'hint_percentages': 'Convierte el porcentaje a decimal y multiplica.',
      'hint_algebra': 'Aísla la variable en un lado.',
      'hint_geometry': 'Usa la fórmula apropiada.',
      'hint_statistics': 'Encuentra la media, mediana o moda.',
    },
    'ar': {
      // Navigation
      'home': 'الرئيسية',
      'games': 'الألعاب',
      'tutor': 'المعلم',
      'rewards': 'المكافآت',
      'profile': 'الملف الشخصي',

      // Common
      'start': 'ابدأ',
      'continue': 'استمر',
      'pause': 'إيقاف مؤقت',
      'resume': 'استئناف',
      'stop': 'إيقاف',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'back': 'رجوع',
      'next': 'التالي',
      'previous': 'السابق',
      'close': 'إغلاق',
      'done': 'تم',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'warning': 'تحذير',
      'info': 'معلومات',

      // Math Operations
      'addition': 'الجمع',
      'subtraction': 'الطرح',
      'multiplication': 'الضرب',
      'division': 'القسمة',
      'fractions': 'الكسور',
      'decimals': 'الأعداد العشرية',
      'percentages': 'النسب المئوية',
      'algebra': 'الجبر',
      'geometry': 'الهندسة',
      'statistics': 'الإحصاء',

      // Game Modes
      'easy': 'سهل',
      'normal': 'عادي',
      'genius': 'عبقري',
      'quantum': 'كمي',

      // Rewards
      'stars': 'النجوم',
      'badges': 'الشارات',
      'achievements': 'الإنجازات',
      'level': 'المستوى',
      'experience': 'الخبرة',
      'points': 'النقاط',

      // User Roles
      'student': 'طالب',
      'parent': 'أب',
      'teacher': 'معلم',
      'school': 'مدرسة',

      // Settings
      'settings': 'الإعدادات',
      'theme': 'المظهر',
      'language': 'اللغة',
      'sound': 'الصوت',
      'notifications': 'الإشعارات',
      'privacy': 'الخصوصية',
      'about': 'حول',
      'help': 'المساعدة',
      'feedback': 'التعليقات',

      // Messages
      'welcome_message': 'مرحباً بك في عبقرية الرياضيات!',
      'congratulations': 'تهانينا!',
      'great_job': 'عمل رائع!',
      'keep_going': 'استمر!',
      'try_again': 'حاول مرة أخرى!',
      'not_quite_right': 'ليس صحيحاً تماماً.',
      'excellent': 'ممتاز!',
      'amazing': 'مذهل!',
      'perfect': 'مثالي!',

      // Errors
      'network_error': 'خطأ في الشبكة. تحقق من اتصالك.',
      'server_error': 'خطأ في الخادم. حاول مرة أخرى لاحقاً.',
      'permission_denied': 'تم رفض الإذن.',
      'invalid_input': 'إدخال غير صحيح.',
      'file_not_found': 'الملف غير موجود.',
      'timeout': 'انتهت مهلة الطلب.',

      // Questions
      'what_is': 'ما هو {expression}؟',
      'solve_for_x': 'حل من أجل x: {equation}',
      'find_the_area': 'أوجد مساحة {shape}.',
      'calculate_percentage': 'احسب {percentage}% من {number}.',
      'simplify_fraction': 'بسط الكسر {fraction}.',

      // Hints
      'hint_addition': 'اجمع الأرقام.',
      'hint_subtraction': 'اطرح الرقم الثاني من الأول.',
      'hint_multiplication': 'اضرب الأرقام.',
      'hint_division': 'اقسم الرقم الأول على الثاني.',
      'hint_fractions': 'أوجد مقاماً مشتركاً.',
      'hint_decimals': 'اصطف النقاط العشرية.',
      'hint_percentages': 'حول النسبة المئوية إلى عشري واضرب.',
      'hint_algebra': 'اعزل المتغير في جانب واحد.',
      'hint_geometry': 'استخدم الصيغة المناسبة.',
      'hint_statistics': 'أوجد المتوسط أو الوسيط أو المنوال.',
    },
  };

  /// Get localized string
  static String getString(String key, Locale locale) {
    final languageCode = locale.languageCode;
    final values = _localizedValues[languageCode] ?? _localizedValues['en']!;
    return values[key] ?? key;
  }

  /// Get localized string with parameters
  static String getStringWithParams(
    String key,
    Locale locale,
    Map<String, String> params,
  ) {
    String text = getString(key, locale);

    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }

    return text;
  }
}
