import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CalendarService {
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3';
  
  static Future<List<Map<String, dynamic>>> getTodayEvents() async {
    try {
      final apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'];
      if (apiKey == null) {
        return _getMockEvents();
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final response = await http.get(
        Uri.parse('$_baseUrl/calendars/primary/events'
            '?key=$apiKey'
            '&timeMin=${startOfDay.toUtc().toIso8601String()}'
            '&timeMax=${endOfDay.toUtc().toIso8601String()}'
            '&singleEvents=true'
            '&orderBy=startTime'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return _getMockEvents();
      }

      final data = jsonDecode(response.body);
      final events = data['items'] as List;
      
      return events.map((event) {
        final start = event['start']['dateTime'] ?? event['start']['date'];
        final end = event['end']['dateTime'] ?? event['end']['date'];
        final startTime = DateTime.parse(start);
        final endTime = DateTime.parse(end);
        
        return {
          'title': event['summary'] ?? 'No Title',
          'start': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
          'end': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          'date': '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}',
        };
      }).toList();
    } catch (e) {
      return _getMockEvents();
    }
  }
  
  static List<Map<String, dynamic>> _getMockEvents() {
    // Mock 데이터 제거 - 실제 데이터만 표시
    return [];
  }
}