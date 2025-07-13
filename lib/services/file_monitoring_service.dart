import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'obsidian_writer.dart';
import '../utils/call_summary_converter.dart';

class FileMonitoringService {
  static const String serviceId = 'file_monitoring_service';
  static const String channelId = 'file_monitoring_channel';
  static const String channelName = '파일 감지 서비스';

  // 기본 모니터링 디렉토리 경로
  static const String defaultMonitoringPath =
      '/storage/emulated/0/Recordings/Summaries/';

  // 데이터베이스 저장용
  static Database? _database;

  // 서비스 초기화
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: '통화 요약 감지 서비스',
        initialNotificationContent: '서비스가 시작되었습니다',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // iOS 백그라운드 처리
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // 서비스 시작 콜백
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // DartPluginRegistrant 필요시 초기화
    DartPluginRegistrant.ensureInitialized();

    // ObsidianWriter 초기화
    try {
      await ObsidianWriter.initDatabase();
      print('ObsidianWriter 데이터베이스 초기화 완료');
    } catch (e) {
      print('ObsidianWriter 초기화 오류: $e');
    }

    // 감지된 파일 목록 데이터베이스 초기화
    await _initializeDatabase();

    // 주기적 파일 스캔 타이머 시작 (10초마다)
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await _scanForNewFiles(service);
        }
      }
    });

    // 서비스 중지 요청 처리
    service.on('stop_service').listen((event) {
      service.stopSelf();
    });

    // 서비스 상태 업데이트
    service.on('set_foreground').listen((event) async {
      await _updateNotification(
        service,
        '통화 요약 감지 서비스 실행 중',
        '새로운 통화 요약 파일을 감지하고 있습니다...',
      );
    });
  }

  // 데이터베이스 초기화 (감지된 파일 목록 저장용)
  static Future<void> _initializeDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'detected_files.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE detected_files(id INTEGER PRIMARY KEY AUTOINCREMENT, file_path TEXT UNIQUE, detected_at TEXT)',
          );
        },
      );
      print('감지 파일 데이터베이스 초기화 완료');
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
    }
  }

  // 사용자 설정에서 모니터링 경로 가져오기
  static Future<String> _getMonitoringPath() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('monitoring_path') ?? defaultMonitoringPath;
    } catch (e) {
      print('모니터링 경로 설정 로드 실패: $e');
      return defaultMonitoringPath;
    }
  }

  // 새로운 파일 스캔 및 통합 처리
  static Future<void> _scanForNewFiles(ServiceInstance service) async {
    try {
      // 설정된 모니터링 경로 가져오기
      String monitoringPath = await _getMonitoringPath();
      final directory = Directory(monitoringPath);

      if (!await directory.exists()) {
        await _updateNotification(
          service,
          '감지 서비스 실행 중',
          '모니터링 폴더를 찾을 수 없습니다: $monitoringPath',
        );
        return;
      }

      // .json 파일만 필터링 (삼성 통화 요약 파일)
      final jsonFiles = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      int processedCount = 0;
      for (File file in jsonFiles) {
        if (await _isNewFile(file.path)) {
          await _processCallSummaryFile(file, service);
          await _recordNewFile(file.path);
          processedCount++;
        }
      }

      await _updateNotification(
        service,
        '통화 요약 감지 서비스 실행 중',
        '경로: $monitoringPath (JSON 파일 ${jsonFiles.length}개, 새로 처리: $processedCount개)',
      );
    } catch (e) {
      print('파일 스캔 오류: $e');
      await _updateNotification(service, '감지 서비스 오류', '파일 스캔 중 오류 발생: $e');
    }
  }

  // 통화 요약 파일 통합 처리
  static Future<void> _processCallSummaryFile(
    File file,
    ServiceInstance service,
  ) async {
    String fileName = file.uri.pathSegments.last;
    String filePath = file.path;

    try {
      // 1. 중복 검사 (ObsidianWriter에서)
      bool isAlreadyProcessed = await ObsidianWriter.isAlreadyProcessed(
        fileName,
      );
      if (isAlreadyProcessed) {
        print('이미 처리된 파일 건너뜀: $fileName');
        return;
      }

      // 2. 파일 내용 읽기
      String content = await file.readAsString();

      // 3. JSON 파싱 및 마크다운 변환
      String markdownContent =
          CallSummaryConverter.convertCallSummaryToMarkdown(content);

      // 4. Obsidian 파일에 저장 (중복 기록도 자동 처리)
      await ObsidianWriter.appendToObsidianFile(markdownContent, fileName);

      // 5. 처리 완료 알림
      service.invoke('new_file_detected', {'file_path': filePath});

      print('통화 요약 파일 처리 완료: $fileName');
    } catch (e) {
      print('파일 처리 오류 ($fileName): $e');
      // 오류가 발생해도 서비스는 계속 실행
    }
  }

  // 새로운 파일인지 확인 (감지 기록 데이터베이스)
  static Future<bool> _isNewFile(String filePath) async {
    if (_database == null) return true;

    try {
      List<Map<String, dynamic>> result = await _database!.query(
        'detected_files',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );
      return result.isEmpty;
    } catch (e) {
      print('파일 검사 오류: $e');
      return true;
    }
  }

  // 새로운 파일 기록
  static Future<void> _recordNewFile(String filePath) async {
    if (_database == null) return;

    try {
      await _database!.insert('detected_files', {
        'file_path': filePath,
        'detected_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('파일 기록 오류: $e');
    }
  }

  // 알림 업데이트
  static Future<void> _updateNotification(
    ServiceInstance service,
    String title,
    String content,
  ) async {
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    }
  }

  // 서비스 시작
  static Future<bool> startService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (isRunning) {
      return true;
    }
    return await service.startService();
  }

  // 서비스 중지
  static Future<bool> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stop_service');
    return true;
  }

  // 서비스 실행 상태 확인
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
