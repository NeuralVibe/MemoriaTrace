import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:io';
import 'services/file_monitoring_service.dart';
import 'screens/service_control_screen.dart';
import 'utils/test_data_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 백그라운드 서비스 초기화
  await FileMonitoringService.initializeService();

  runApp(const MemoriaTraceApp());
}

class MemoriaTraceApp extends StatelessWidget {
  const MemoriaTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoriaTrace',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasStoragePermission = false;
  bool _isServiceRunning = false;
  String _statusMessage = "권한 확인 중...";
  String _lastDetectedFile = "";
  int _detectedFilesCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkServiceStatus();
    _setupServiceListener();
  }

  // 필요한 권한들을 요청하는 함수
  Future<void> _requestPermissions() async {
    try {
      // Android 11 (API 30) 이상에서는 MANAGE_EXTERNAL_STORAGE 권한 필요
      if (Platform.isAndroid) {
        // 먼저 기본 저장소 권한 확인
        PermissionStatus storageStatus = await Permission.storage.status;
        PermissionStatus manageStorageStatus =
            await Permission.manageExternalStorage.status;

        setState(() {
          _statusMessage = "저장소 권한 요청 중...";
        });

        // 권한이 없으면 요청
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        if (!manageStorageStatus.isGranted) {
          manageStorageStatus = await Permission.manageExternalStorage
              .request();
        }

        // 권한 상태 업데이트
        bool hasPermission =
            storageStatus.isGranted || manageStorageStatus.isGranted;

        setState(() {
          _hasStoragePermission = hasPermission;
          _statusMessage = hasPermission
              ? "모든 권한이 승인되었습니다!"
              : "저장소 접근 권한이 필요합니다.";
        });

        if (hasPermission) {
          await _initializeApp();
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = "권한 요청 중 오류 발생: $e";
      });
    }
  }

  // 앱 초기화 함수
  Future<void> _initializeApp() async {
    try {
      // 앱 문서 디렉토리 경로 가져오기
      Directory appDocDir = await getApplicationDocumentsDirectory();

      setState(() {
        _statusMessage =
            "앱이 성공적으로 초기화되었습니다!\n"
            "문서 디렉토리: ${appDocDir.path}";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "앱 초기화 중 오류 발생: $e";
      });
    }
  }

  // 서비스 상태 확인
  Future<void> _checkServiceStatus() async {
    try {
      bool isRunning = await FileMonitoringService.isServiceRunning();
      setState(() {
        _isServiceRunning = isRunning;
      });
    } catch (e) {
      print('서비스 상태 확인 오류: $e');
    }
  }

  // 서비스 리스너 설정
  void _setupServiceListener() {
    try {
      final service = FlutterBackgroundService();
      service.on('new_file_detected').listen((event) {
        if (event != null && event['file_path'] != null) {
          setState(() {
            _lastDetectedFile = event['file_path'];
            _detectedFilesCount++;
          });

          // 스낵바로 알림 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('새 파일 감지: ${event['file_path']}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      print('서비스 리스너 설정 오류: $e');
    }
  }

  // 서비스 시작
  Future<void> _startMonitoringService() async {
    try {
      bool success = await FileMonitoringService.startService();
      if (success) {
        setState(() {
          _isServiceRunning = true;
        });

        // 포그라운드 모드 설정
        final service = FlutterBackgroundService();
        service.invoke('set_foreground');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일 감지 서비스가 시작되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('서비스 시작에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서비스 시작 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 서비스 중지
  Future<void> _stopMonitoringService() async {
    try {
      await FileMonitoringService.stopService();
      setState(() {
        _isServiceRunning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('파일 감지 서비스가 중지되었습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서비스 중지 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 테스트 데이터 생성
  Future<void> _generateTestData() async {
    try {
      const String monitoringPath = '/storage/emulated/0/Recordings/Summaries/';
      await TestDataGenerator.createSampleJsonFiles(monitoringPath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 JSON 파일이 생성되었습니다. 서비스를 시작하면 자동으로 감지됩니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('테스트 데이터 생성 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MemoriaTrace'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasStoragePermission ? Icons.check_circle : Icons.warning,
              size: 80,
              color: _hasStoragePermission ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              'MemoriaTrace',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 앱 상태 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('앱 상태', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 서비스 상태 카드
            if (_hasStoragePermission)
              Card(
                color: _isServiceRunning ? Colors.green[50] : Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isServiceRunning
                                ? Icons.play_circle
                                : Icons.pause_circle,
                            color: _isServiceRunning
                                ? Colors.green
                                : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '파일 감지 서비스',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isServiceRunning ? '실행 중' : '중지됨',
                        style: TextStyle(
                          color: _isServiceRunning ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isServiceRunning && _detectedFilesCount > 0) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        Text(
                          '감지된 파일: $_detectedFilesCount개',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_lastDetectedFile.isNotEmpty)
                          Text(
                            '최근: ${_lastDetectedFile.split('/').last}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                      ],
                      if (_isServiceRunning)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '모니터링 경로:\n/storage/emulated/0/Recordings/Summaries/',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 제어 버튼들
            if (!_hasStoragePermission)
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.security),
                label: const Text('권한 다시 요청'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

            if (_hasStoragePermission && !_isServiceRunning)
              ElevatedButton.icon(
                onPressed: _startMonitoringService,
                icon: const Icon(Icons.play_arrow),
                label: const Text('서비스 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            if (_hasStoragePermission && _isServiceRunning)
              ElevatedButton.icon(
                onPressed: _stopMonitoringService,
                icon: const Icon(Icons.stop),
                label: const Text('서비스 중지'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),

            const SizedBox(height: 10),

            if (_hasStoragePermission)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceControlScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.folder),
                label: const Text('감지된 파일 보기'),
              ),

            const SizedBox(height: 10),

            // 테스트 데이터 생성 버튼 (개발용)
            if (_hasStoragePermission)
              OutlinedButton.icon(
                onPressed: _generateTestData,
                icon: const Icon(Icons.science),
                label: const Text('테스트 데이터 생성'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),

            // 테스트 데이터 생성 버튼
            if (_hasStoragePermission && !_isServiceRunning)
              ElevatedButton.icon(
                onPressed: _generateTestData,
                icon: const Icon(Icons.file_download),
                label: const Text('테스트 데이터 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
