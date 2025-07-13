import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'markdown_service.dart';
import 'obsidian_writer.dart';
import '../utils/call_summary_converter.dart';

class FileMonitoringService {
  static const String serviceId = 'file_monitoring_service';
  static const String channelId = 'file_monitoring_channel';
  static const String channelName = '파일 감지 서비스';

  // 모니터링할 디렉토리 경로
  static const String monitoringPath =
      '/storage/emulated/0/Recordings/Summaries/';

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
        initialNotificationContent: '파일 감지 서비스를 준비 중입니다...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // iOS 백그라운드 처리 (사용하지 않음)
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  // 서비스 시작 진입점
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // DartPluginRegistrant 필요시 초기화
    DartPluginRegistrant.ensureInitialized();

    // 데이터베이스 초기화
    await _initializeDatabase();

    // ObsidianWriter 초기화
    try {
      await ObsidianWriter.initDatabase();
      print('ObsidianWriter 데이터베이스 초기화 완료');
    } catch (e) {
      print('ObsidianWriter 초기화 오류: $e');
    }

    // 주기적 파일 스캔 타이머 시작
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
        '새로운 파일을 감지하고 있습니다...',
      );
    });
  }

  // 데이터베이스 초기화 (감지된 파일 목록 저장용)
  static Future<void> _initializeDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'detected_files.db');

      await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE detected_files(id INTEGER PRIMARY KEY AUTOINCREMENT, file_path TEXT UNIQUE, detected_at TEXT)',
          );
        },
      );
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
    }
  }

  // 새로운 파일 스캔
  static Future<void> _scanForNewFiles(ServiceInstance service) async {
    try {
      final directory = Directory(monitoringPath);

      if (!await directory.exists()) {
        await _updateNotification(
          service,
          '감지 서비스 실행 중',
          '모니터링 폴더를 찾을 수 없습니다: $monitoringPath',
        );
        return;
      }

      // .txt 파일만 필터링 (JSON 형태의 통화 요약 파일)
      final txtFiles = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.txt'))
          .cast<File>()
          .toList();

      int newFilesCount = 0;
      int convertedCount = 0;

      for (File file in txtFiles) {
        if (await _isNewFile(file.path)) {
          await _recordNewFile(file.path);
          print('새로운 파일 감지: ${file.path}');
          newFilesCount++;

          // JSON 형태의 통화 요약 파일인지 확인 후 마크다운 변환
          try {
            await _processCallSummaryFile(file.path);
            convertedCount++;
            print('마크다운 변환 완료: ${file.path}');
          } catch (e) {
            print('마크다운 변환 실패: ${file.path} - $e');
          }

          // 메인 앱에 새 파일 감지 알림
          service.invoke('new_file_detected', {
            'file_path': file.path,
            'detected_at': DateTime.now().toIso8601String(),
            'converted_to_markdown': convertedCount > 0,
          });
        }
      }

      // 알림 업데이트
      if (newFilesCount > 0) {
        String message = convertedCount > 0
            ? '$newFilesCount개의 새로운 파일 발견, $convertedCount개 마크다운 변환 완료!'
            : '$newFilesCount개의 새로운 파일을 발견했습니다!';

        await _updateNotification(service, '통화 요약 감지 서비스 실행 중', message);
      } else {
        await _updateNotification(
          service,
          '통화 요약 감지 서비스 실행 중',
          '${txtFiles.length}개 파일 확인 완료 (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})',
        );
      }
    } catch (e) {
      print('파일 스캔 오류: $e');
      await _updateNotification(service, '감지 서비스 오류', '파일 스캔 중 오류 발생: $e');
    }
  }

  // 새로운 파일인지 확인
  static Future<bool> _isNewFile(String filePath) async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'detected_files.db');
      final db = await openDatabase(path);

      final result = await db.query(
        'detected_files',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );

      await db.close();
      return result.isEmpty;
    } catch (e) {
      print('새 파일 확인 오류: $e');
      return false;
    }
  }

  // 새로운 파일 기록
  static Future<void> _recordNewFile(String filePath) async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'detected_files.db');
      final db = await openDatabase(path);

      await db.insert('detected_files', {
        'file_path': filePath,
        'detected_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.close();
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

  // 통화 요약 파일 처리 (JSON → 마크다운 변환 + 옵시디언 저장)
  static Future<void> _processCallSummaryFile(String filePath) async {
    try {
      // 파일명 추출 (중복 처리 확인용)
      String fileName = filePath.split('/').last;

      // 이미 처리된 파일인지 확인
      bool alreadyProcessed = await ObsidianWriter.isAlreadyProcessed(fileName);
      if (alreadyProcessed) {
        print('이미 처리된 파일 건너뛰기: $fileName');
        return;
      }

      // 파일 내용 읽기
      File file = File(filePath);
      String content = await file.readAsString();

      // JSON 형태인지 간단히 확인
      if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
        // 1. 마크다운 변환
        String markdownPath = await MarkdownService.processJsonFile(filePath);
        print('마크다운 변환 성공: $filePath → $markdownPath');

        // 2. JSON 파싱하여 통화자 정보 추출
        String markdownContent =
            CallSummaryConverter.convertCallSummaryToMarkdown(content);

        // 3. 옵시디언 파일에 저장
        await ObsidianWriter.appendToObsidianFile(markdownContent, fileName);

        print('옵시디언 파일 저장 및 처리 완료: $fileName');
      } else {
        // JSON이 아닌 일반 텍스트 파일
        print('일반 텍스트 파일로 인식: $filePath');
      }
    } catch (e) {
      // 변환 실패시 로그만 남기고 계속 진행
      print('파일 처리 중 오류 (계속 진행): $filePath - $e');
    }
  }

  // 서비스 시작
  static Future<bool> startService() async {
    final service = FlutterBackgroundService();

    // 서비스가 이미 실행 중인지 확인
    bool isRunning = await service.isRunning();
    if (isRunning) {
      return true;
    }

    // 서비스 시작
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
