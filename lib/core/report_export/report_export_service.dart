import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

/// Report export types
enum ReportExportType { pdf, csv, json }

/// Report content types
enum ReportContentType {
  progressReport,
  gameResults,
  quizResults,
  analytics,
  userData,
  custom,
}

/// Report export model
class ReportExport {
  final String id;
  final ReportContentType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? userId;
  final ReportExportType exportType;
  final String? filePath;

  const ReportExport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.data = const {},
    required this.createdAt,
    this.userId,
    this.exportType = ReportExportType.pdf,
    this.filePath,
  });

  ReportExport copyWith({
    String? id,
    ReportContentType? type,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? userId,
    ReportExportType? exportType,
    String? filePath,
  }) {
    return ReportExport(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      exportType: exportType ?? this.exportType,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'exportType': exportType.name,
      'filePath': filePath,
    };
  }

  factory ReportExport.fromJson(Map<String, dynamic> json) {
    return ReportExport(
      id: json['id'] as String,
      type: ReportContentType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
      exportType: ReportExportType.values.firstWhere(
        (e) => e.name == json['exportType'],
      ),
      filePath: json['filePath'] as String?,
    );
  }
}

/// Report export service for Math Genius
class ReportExportService {
  static const String _reportsKey = 'exported_reports';
  static const String _templatesKey = 'report_templates';

  final SharedPreferences _prefs;

  ReportExportService(this._prefs);

  /// Export progress report as PDF
  Future<String> exportProgressReportAsPDF({
    required String userId,
    required Map<String, dynamic> progressData,
    String? reportTitle,
    String? studentName,
  }) async {
    try {
      final report = ReportExport(
        id: _generateId(),
        type: ReportContentType.progressReport,
        title: reportTitle ?? 'Math Genius Progress Report',
        description: 'Progress report for ${studentName ?? 'Student'}',
        data: progressData,
        createdAt: DateTime.now(),
        userId: userId,
        exportType: ReportExportType.pdf,
      );

      final pdfBytes = await _generateProgressReportPDF(report);
      final filePath = await _savePDFFile(report.id, pdfBytes);

      final updatedReport = report.copyWith(filePath: filePath);
      await _saveReport(updatedReport);

      if (kDebugMode) {
        print('Progress report exported as PDF: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting progress report as PDF: $e');
      }
      rethrow;
    }
  }

  /// Export game results as PDF
  Future<String> exportGameResultsAsPDF({
    required String userId,
    required Map<String, dynamic> gameData,
    String? reportTitle,
  }) async {
    try {
      final report = ReportExport(
        id: _generateId(),
        type: ReportContentType.gameResults,
        title: reportTitle ?? 'Math Genius Game Results',
        description: 'Game results and performance analysis',
        data: gameData,
        createdAt: DateTime.now(),
        userId: userId,
        exportType: ReportExportType.pdf,
      );

      final pdfBytes = await _generateGameResultsPDF(report);
      final filePath = await _savePDFFile(report.id, pdfBytes);

      final updatedReport = report.copyWith(filePath: filePath);
      await _saveReport(updatedReport);

      if (kDebugMode) {
        print('Game results exported as PDF: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting game results as PDF: $e');
      }
      rethrow;
    }
  }

  /// Export quiz results as CSV
  Future<String> exportQuizResultsAsCSV({
    required String userId,
    required Map<String, dynamic> quizData,
    String? reportTitle,
  }) async {
    try {
      final report = ReportExport(
        id: _generateId(),
        type: ReportContentType.quizResults,
        title: reportTitle ?? 'Math Genius Quiz Results',
        description: 'Quiz results and performance data',
        data: quizData,
        createdAt: DateTime.now(),
        userId: userId,
        exportType: ReportExportType.csv,
      );

      final csvContent = await _generateQuizResultsCSV(report);
      final filePath = await _saveCSVFile(report.id, csvContent);

      final updatedReport = report.copyWith(filePath: filePath);
      await _saveReport(updatedReport);

      if (kDebugMode) {
        print('Quiz results exported as CSV: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting quiz results as CSV: $e');
      }
      rethrow;
    }
  }

  /// Export analytics as JSON
  Future<String> exportAnalyticsAsJSON({
    required String userId,
    required Map<String, dynamic> analyticsData,
    String? reportTitle,
  }) async {
    try {
      final report = ReportExport(
        id: _generateId(),
        type: ReportContentType.analytics,
        title: reportTitle ?? 'Math Genius Analytics Report',
        description: 'Analytics and performance data',
        data: analyticsData,
        createdAt: DateTime.now(),
        userId: userId,
        exportType: ReportExportType.json,
      );

      final jsonContent = jsonEncode(analyticsData);
      final filePath = await _saveJSONFile(report.id, jsonContent);

      final updatedReport = report.copyWith(filePath: filePath);
      await _saveReport(updatedReport);

      if (kDebugMode) {
        print('Analytics exported as JSON: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting analytics as JSON: $e');
      }
      rethrow;
    }
  }

  /// Export user data as JSON
  Future<String> exportUserDataAsJSON({
    required String userId,
    required Map<String, dynamic> userData,
    String? reportTitle,
  }) async {
    try {
      final report = ReportExport(
        id: _generateId(),
        type: ReportContentType.userData,
        title: reportTitle ?? 'Math Genius User Data Export',
        description: 'Complete user data export',
        data: userData,
        createdAt: DateTime.now(),
        userId: userId,
        exportType: ReportExportType.json,
      );

      final jsonContent = jsonEncode(userData);
      final filePath = await _saveJSONFile(report.id, jsonContent);

      final updatedReport = report.copyWith(filePath: filePath);
      await _saveReport(updatedReport);

      if (kDebugMode) {
        print('User data exported as JSON: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting user data as JSON: $e');
      }
      rethrow;
    }
  }

  /// Get all exported reports
  Future<List<ReportExport>> getAllReports({String? userId}) async {
    try {
      final reportsString = _prefs.getString(_reportsKey);
      if (reportsString == null) return [];

      final reportsList = jsonDecode(reportsString) as List;
      final allReports = reportsList
          .map(
            (report) => ReportExport.fromJson(report as Map<String, dynamic>),
          )
          .toList();

      if (userId != null) {
        return allReports.where((report) => report.userId == userId).toList();
      }

      return allReports;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all reports: $e');
      }
      return [];
    }
  }

  /// Delete report
  Future<void> deleteReport(String reportId) async {
    try {
      final reports = await getAllReports();
      final report = reports.firstWhere((r) => r.id == reportId);

      // Delete file if exists
      if (report.filePath != null) {
        final file = File(report.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from reports list
      reports.removeWhere((r) => r.id == reportId);
      await _saveAllReports(reports);

      if (kDebugMode) {
        print('Report deleted: $reportId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting report: $e');
      }
    }
  }

  /// Generate progress report PDF
  Future<Uint8List> _generateProgressReportPDF(ReportExport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  report.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${report.createdAt.toString()}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(report.description, style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              ..._buildProgressReportContent(report.data),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate game results PDF
  Future<Uint8List> _generateGameResultsPDF(ReportExport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  report.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${report.createdAt.toString()}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(report.description, style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              ..._buildGameResultsContent(report.data),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate quiz results CSV
  Future<String> _generateQuizResultsCSV(ReportExport report) async {
    final csvBuffer = StringBuffer();

    // CSV header
    csvBuffer.writeln('Question,Answer,Correct,Time Spent,Score');

    // CSV data
    final quizData = report.data;
    if (quizData['questions'] != null) {
      final questions = quizData['questions'] as List;
      for (final question in questions) {
        csvBuffer.writeln(
          '${question['question']},${question['answer']},${question['correct']},${question['timeSpent']},${question['score']}',
        );
      }
    }

    return csvBuffer.toString();
  }

  /// Build progress report content
  List<pw.Widget> _buildProgressReportContent(Map<String, dynamic> data) {
    final widgets = <pw.Widget>[];

    if (data['topics'] != null) {
      widgets.add(pw.Header(level: 1, child: pw.Text('Topic Performance')));

      final topics = data['topics'] as Map<String, dynamic>;
      for (final entry in topics.entries) {
        final topic = entry.key;
        final stats = entry.value as Map<String, dynamic>;

        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  topic,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Questions: ${stats['totalQuestions']}'),
                pw.Text('Correct: ${stats['correctAnswers']}'),
                pw.Text(
                  'Accuracy: ${((stats['correctAnswers'] / stats['totalQuestions']) * 100).toStringAsFixed(1)}%',
                ),
                pw.SizedBox(height: 10),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Build game results content
  List<pw.Widget> _buildGameResultsContent(Map<String, dynamic> data) {
    final widgets = <pw.Widget>[];

    if (data['games'] != null) {
      widgets.add(pw.Header(level: 1, child: pw.Text('Game Results')));

      final games = data['games'] as List;
      for (final game in games) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  game['gameType'],
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Score: ${game['score']}'),
                pw.Text('Time: ${game['timeSpent']}'),
                pw.Text('Date: ${game['date']}'),
                pw.SizedBox(height: 10),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Save PDF file
  Future<String> _savePDFFile(String reportId, Uint8List pdfBytes) async {
    final directory = await _getReportsDirectory();
    final file = File('${directory.path}/report_$reportId.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Save CSV file
  Future<String> _saveCSVFile(String reportId, String csvContent) async {
    final directory = await _getReportsDirectory();
    final file = File('${directory.path}/report_$reportId.csv');
    await file.writeAsString(csvContent);
    return file.path;
  }

  /// Save JSON file
  Future<String> _saveJSONFile(String reportId, String jsonContent) async {
    final directory = await _getReportsDirectory();
    final file = File('${directory.path}/report_$reportId.json');
    await file.writeAsString(jsonContent);
    return file.path;
  }

  /// Get reports directory
  Future<Directory> _getReportsDirectory() async {
    final appDir = await Directory.systemTemp.createTemp('math_genius_reports');
    return appDir;
  }

  /// Save report to storage
  Future<void> _saveReport(ReportExport report) async {
    try {
      final reports = await getAllReports();
      reports.add(report);
      await _saveAllReports(reports);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving report: $e');
      }
    }
  }

  /// Save all reports
  Future<void> _saveAllReports(List<ReportExport> reports) async {
    try {
      final reportsJson = jsonEncode(reports.map((r) => r.toJson()).toList());
      await _prefs.setString(_reportsKey, reportsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving all reports: $e');
      }
    }
  }

  /// Save report template
  Future<void> saveReportTemplate(
    String templateName,
    Map<String, dynamic> template,
  ) async {
    try {
      final templates = await _loadAllTemplates();
      templates[templateName] = template;
      await _prefs.setString(_templatesKey, jsonEncode(templates));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving report template: $e');
      }
    }
  }

  /// Load all report templates
  Future<Map<String, dynamic>> _loadAllTemplates() async {
    try {
      final templatesString = _prefs.getString(_templatesKey);
      if (templatesString == null) return {};
      return Map<String, dynamic>.from(jsonDecode(templatesString));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading report templates: $e');
      }
      return {};
    }
  }

  /// Get report template
  Future<Map<String, dynamic>?> getReportTemplate(String templateName) async {
    try {
      final templates = await _loadAllTemplates();
      return templates[templateName];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting report template: $e');
      }
      return null;
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }

  /// Clear all reports
  Future<void> clearAllReports() async {
    try {
      final reports = await getAllReports();
      for (final report in reports) {
        if (report.filePath != null) {
          final file = File(report.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      await _prefs.remove(_reportsKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all reports: $e');
      }
    }
  }
}

/// Riverpod providers for report export
final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  throw UnimplementedError('ReportExportService must be initialized');
});

final exportedReportsProvider =
    FutureProvider.family<List<ReportExport>, String?>((ref, userId) async {
      final reportExportService = ref.read(reportExportServiceProvider);
      return reportExportService.getAllReports(userId: userId);
    });
