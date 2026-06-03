import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/env/app_env.dart';
import '../../tasks/domain/task.dart';

enum ActiveDays { weekdays, everyday }
enum ScheduleStrategy { deadlineFirst, priorityFirst }

final class AutoScheduleRequest {
  final TimeOfDayRange activeHours;
  final ActiveDays activeDays;
  final ScheduleStrategy strategy;
  final int bufferMinutes;
  final DateTime nowLocal;
  final DateTime horizonEndLocal;

  const AutoScheduleRequest({
    required this.activeHours,
    required this.activeDays,
    required this.strategy,
    required this.bufferMinutes,
    required this.nowLocal,
    required this.horizonEndLocal,
  });
}

final class TimeOfDayRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeOfDayRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  String startHHmm() =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String endHHmm() =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

final class ScheduledResult {
  final int taskId;
  final DateTime scheduledAtLocal;

  const ScheduledResult({required this.taskId, required this.scheduledAtLocal});
}

final class GeminiSchedulingService {
static const List<String> _models = [
  'gemini-1.5-flash',
  'gemini-1.5-pro',
  'gemini-pro',
  'gemini-2.5-flash'

];

  Future<List<ScheduledResult>> createSchedule({
    required AutoScheduleRequest req,
    required List<Task> unscheduledTasks,
    required List<Task> existingScheduledTasks,
  }) async {
    final apiKey = AppEnv.geminiApiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY belum di-set. Jalankan dengan --dart-define=GEMINI_API_KEY=...',
      );
    }

    final prompt = _buildPrompt(req, unscheduledTasks, existingScheduledTasks);

    Object? lastErr;

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            maxOutputTokens: 2048,
            // Note: responseMimeType exists in the REST API; in this Dart SDK version,
            // it may or may not be available depending on release. We rely on prompt + robust parsing.
          ),
        );

        final response = await model.generateContent([
          Content.text(prompt),
        ]);

        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw StateError('Gemini returned empty text (model=$modelName).');
        }

        final jsonText = _coerceToJsonObject(text);
        final scheduleJson = jsonDecode(jsonText) as Map<String, dynamic>;

        final rawItems = scheduleJson['schedule'];
        if (rawItems is! List) {
          throw const FormatException('Invalid response: "schedule" must be a list.');
        }

        final items = rawItems.cast<Map<String, dynamic>>();
        return items.map((m) {
          final taskId = (m['task_id'] as num).toInt();
          final raw = (m['scheduled_at'] as String).trim();
          final dt = DateTime.parse(raw); // local time string without Z
          return ScheduledResult(taskId: taskId, scheduledAtLocal: dt);
        }).toList(growable: false);
      } catch (e) {
        lastErr = 'Gemini model=$modelName failed: $e';
      }
    }

    throw StateError('All Gemini models failed. Last error: $lastErr');
  }

  String _coerceToJsonObject(String s) {
    var t = s.trim();

    // Strip markdown fences if the model still adds them
    t = t
        .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
        .trim();

    if (t.startsWith('{') && t.endsWith('}')) return t;

    final i = t.indexOf('{');
    final j = t.lastIndexOf('}');
    if (i >= 0 && j > i) return t.substring(i, j + 1);

    throw FormatException('Model did not return a JSON object. Raw: $s');
  }

  String _buildPrompt(
    AutoScheduleRequest req,
    List<Task> unscheduled,
    List<Task> existingScheduled,
  ) {
    final now = req.nowLocal;
    final horizon = req.horizonEndLocal;

    String taskJson(Task t) {
      return jsonEncode({
        "id": t.id,
        "title": t.title,
        "description": t.description,
        "deadline": t.deadline?.toIso8601String(),
        "priority": t.priority.label(),
      });
    }

    String existingJson(Task t) {
      return jsonEncode({
        "id": t.id,
        "title": t.title,
        "scheduled_at": t.scheduledAt!.toIso8601String(),
      });
    }

    return '''
Return STRICT JSON ONLY (no markdown/backticks), schema:
{
  "schedule": [
    { "task_id": <int>, "scheduled_at": "YYYY-MM-DDTHH:mm:ss" }
  ]
}

Constraints:
- Use LOCAL device time (no timezone suffix like Z).
- Now: ${now.toIso8601String()}
- Horizon end (for tasks without deadline): ${horizon.toIso8601String()}
- Active hours: ${req.activeHours.startHHmm()} - ${req.activeHours.endHHmm()}
- Active days: ${req.activeDays == ActiveDays.weekdays ? "Weekdays (Mon-Fri)" : "Everyday (Mon-Sun)"}
- Avoid conflicts with existing scheduled tasks (do not place two tasks at the exact same start time).
- If task has deadline, schedule on/before deadline when possible.
- If no deadline, schedule within horizon.
- Strategy: ${req.strategy == ScheduleStrategy.deadlineFirst ? "deadline-first" : "priority-first"}

Unscheduled tasks (schedule ALL):
${unscheduled.map(taskJson).join("\n")}

Existing scheduled tasks (avoid exact-start conflicts):
${existingScheduled.map(existingJson).join("\n")}
'''.trim();
  }
}