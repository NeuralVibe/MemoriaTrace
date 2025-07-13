import 'dart:io';
import 'dart:convert';

/// 디버그 로그 유틸리티
class DebugLogger {
  static final List<String> _logs = [];
  static const int maxLogs = 100;

  /// 로그 메시지를 추가합니다
  static void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';

    // 콘솔 출력
    print(logMessage);

    // 메모리에 저장 (최근 100개만)
    _logs.add(logMessage);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
  }

  /// 저장된 로그들을 반환합니다
  static List<String> getLogs() {
    return List.from(_logs);
  }

  /// 로그를 클리어합니다
  static void clearLogs() {
    _logs.clear();
  }

  /// 로그를 파일로 저장합니다
  static Future<String?> saveLogsToFile() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        return null;
      }

      final fileName =
          'MemoriaTrace_Log_${DateTime.now().toString().replaceAll(':', '-').substring(0, 19)}.txt';
      final file = File('${directory.path}/$fileName');

      final content = _logs.join('\n');
      await file.writeAsString(content, encoding: utf8);

      return file.path;
    } catch (e) {
      log('로그 파일 저장 실패: $e');
      return null;
    }
  }
}
