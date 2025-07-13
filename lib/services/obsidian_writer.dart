import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObsidianWriter {
  static Database? _database;
  static const String _databaseName = 'memoria_trace.db';
  static const String _tableName = 'processed_files';

  /// 데이터베이스 초기화
  static Future<void> initDatabase() async {
    if (_database != null) return;

    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String dbPath = path.join(documentsDirectory.path, _databaseName);

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              filename TEXT UNIQUE NOT NULL,
              processed_at TEXT NOT NULL,
              obsidian_path TEXT
            )
          ''');
          print('데이터베이스 테이블 생성 완료');
        },
        onOpen: (db) {
          print('데이터베이스 열기 완료: $dbPath');
        },
      );
      print('ObsidianWriter 데이터베이스 초기화 완료');
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
      rethrow;
    }
  }

  /// 파일이 이미 처리되었는지 확인
  static Future<bool> isAlreadyProcessed(String filename) async {
    await initDatabase();
    if (_database == null) return false;

    try {
      List<Map<String, dynamic>> result = await _database!.query(
        _tableName,
        where: 'filename = ?',
        whereArgs: [filename],
      );

      bool isProcessed = result.isNotEmpty;
      print('중복 검사 - $filename: ${isProcessed ? "이미 처리됨" : "새 파일"}');
      return isProcessed;
    } catch (e) {
      print('중복 검사 오류: $e');
      return false;
    }
  }

  /// 처리된 파일로 기록
  static Future<void> markAsProcessed(
    String filename,
    String obsidianPath,
  ) async {
    await initDatabase();
    if (_database == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다.');
    }

    try {
      await _database!.insert(_tableName, {
        'filename': filename,
        'processed_at': DateTime.now().toIso8601String(),
        'obsidian_path': obsidianPath,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      print('처리 기록 저장: $filename');
    } catch (e) {
      print('처리 기록 저장 오류: $e');
      rethrow;
    }
  }

  /// 옵시디언 볼트에 마크다운 파일 추가
  static Future<void> appendToObsidianFile(
    String markdownContent,
    String originalFilename,
  ) async {
    try {
      // SharedPreferences에서 옵시디언 경로 가져오기
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? obsidianPath = prefs.getString('obsidian_path');

      if (obsidianPath == null || obsidianPath.isEmpty) {
        // 기본 경로 설정
        Directory appDocDir = await getApplicationDocumentsDirectory();
        obsidianPath = '${appDocDir.path}/ObsidianVault';
        await prefs.setString('obsidian_path', obsidianPath);
      }

      // 옵시디언 볼트 디렉토리 생성
      Directory obsidianDir = Directory(obsidianPath);
      if (!await obsidianDir.exists()) {
        await obsidianDir.create(recursive: true);
      }

      // 통화 기록 디렉토리 생성
      Directory callsDir = Directory('$obsidianPath/Call Records');
      if (!await callsDir.exists()) {
        await callsDir.create(recursive: true);
      }

      // 파일명 생성 (원본 파일명 기반)
      String baseFilename = originalFilename.replaceAll('.json', '');
      String markdownFilename = '$baseFilename.md';
      String fullPath = '${callsDir.path}/$markdownFilename';

      // 마크다운 파일 생성
      File markdownFile = File(fullPath);
      await markdownFile.writeAsString(markdownContent, encoding: utf8);

      print('옵시디언 파일 생성: $fullPath');

      // 처리 기록 저장
      await markAsProcessed(originalFilename, fullPath);
    } catch (e) {
      print('옵시디언 파일 생성 오류: $e');
      rethrow;
    }
  }

  /// 처리 통계 가져오기
  static Future<Map<String, dynamic>> getProcessingStatistics() async {
    await initDatabase();
    if (_database == null) {
      return {
        'total_processed': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }

    try {
      List<Map<String, dynamic>> result = await _database!.rawQuery(
        'SELECT COUNT(*) as total_processed FROM $_tableName',
      );

      int totalProcessed = result.first['total_processed'] ?? 0;

      return {
        'total_processed': totalProcessed,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('통계 조회 실패: $e');
      return {
        'total_processed': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 처리된 파일 목록 가져오기
  static Future<List<String>> getProcessedFiles() async {
    await initDatabase();
    if (_database == null) {
      return [];
    }

    try {
      List<Map<String, dynamic>> result = await _database!.query(
        _tableName,
        orderBy: 'processed_at DESC',
      );

      return result.map((row) => row['filename'] as String).toList();
    } catch (e) {
      print('처리된 파일 목록 조회 실패: $e');
      return [];
    }
  }

  /// 모든 처리 기록 삭제
  static Future<void> clearAllProcessedRecords() async {
    await initDatabase();
    if (_database == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다.');
    }

    try {
      await _database!.delete(_tableName);
      print('모든 처리 기록이 삭제되었습니다.');
    } catch (e) {
      print('처리 기록 삭제 실패: $e');
      rethrow;
    }
  }

  /// 특정 파일의 처리 기록 삭제
  static Future<void> removeProcessedRecord(String filename) async {
    await initDatabase();
    if (_database == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다.');
    }

    try {
      int count = await _database!.delete(
        _tableName,
        where: 'filename = ?',
        whereArgs: [filename],
      );

      if (count > 0) {
        print('처리 기록 삭제됨: $filename');
      } else {
        print('삭제할 기록을 찾을 수 없음: $filename');
      }
    } catch (e) {
      print('처리 기록 삭제 실패: $e');
      rethrow;
    }
  }

  /// 데이터베이스 연결 해제
  static Future<void> closeDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('데이터베이스 연결이 해제되었습니다.');
      }
    } catch (e) {
      print('데이터베이스 연결 해제 오류: $e');
    }
  }
}
