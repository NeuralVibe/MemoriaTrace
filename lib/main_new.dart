import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
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
  String _statusMessage = "권한 확인 중...";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // 필요한 권한들을 요청하는 함수
  Future<void> _requestPermissions() async {
    try {
      // Android 11 (API 30) 이상에서는 MANAGE_EXTERNAL_STORAGE 권한 필요
      if (Platform.isAndroid) {
        // MANAGE_EXTERNAL_STORAGE 권한 확인 (Android 11+에서 주로 사용)
        PermissionStatus manageStorageStatus =
            await Permission.manageExternalStorage.status;

        setState(() {
          _statusMessage = "저장소 권한 요청 중...";
        });

        // MANAGE_EXTERNAL_STORAGE 권한이 없으면 요청
        if (!manageStorageStatus.isGranted) {
          manageStorageStatus = await Permission.manageExternalStorage
              .request();
        }

        // 권한 상태 업데이트
        bool hasPermission = manageStorageStatus.isGranted;

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
            if (!_hasStoragePermission)
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('권한 다시 요청'),
              ),
            if (_hasStoragePermission)
              ElevatedButton(
                onPressed: () {
                  // TODO: 메인 기능으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('메인 기능은 다음 단계에서 구현됩니다.')),
                  );
                },
                child: const Text('시작하기'),
              ),
          ],
        ),
      ),
    );
  }
}
