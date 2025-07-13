import 'package:flutter/material.dart';
import '../services/file_monitoring_service.dart';
import 'markdown_list_screen.dart';
import 'obsidian_settings_screen.dart';

class ServiceControlScreen extends StatefulWidget {
  const ServiceControlScreen({super.key});

  @override
  State<ServiceControlScreen> createState() => _ServiceControlScreenState();
}

class _ServiceControlScreenState extends State<ServiceControlScreen> {
  bool _isServiceRunning = false;
  List<Map<String, dynamic>> _detectedFiles = [];

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadDetectedFiles();
  }

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

  Future<void> _loadDetectedFiles() async {
    // TODO: 데이터베이스에서 감지된 파일 목록 로드
    // 현재는 임시 데이터로 대체
    setState(() {
      _detectedFiles = [
        {
          'file_path':
              '/storage/emulated/0/Recordings/Summaries/call_summary_20240713_140512.txt',
          'detected_at': '2024-07-13 14:05:12',
        },
        {
          'file_path':
              '/storage/emulated/0/Recordings/Summaries/call_summary_20240713_150230.txt',
          'detected_at': '2024-07-13 15:02:30',
        },
      ];
    });
  }

  Future<void> _startService() async {
    bool success = await FileMonitoringService.startService();
    if (success) {
      setState(() {
        _isServiceRunning = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일 감지 서비스가 시작되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _stopService() async {
    await FileMonitoringService.stopService();
    setState(() {
      _isServiceRunning = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('파일 감지 서비스가 중지되었습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('파일 감지 서비스'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ObsidianSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 서비스 상태 카드
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
                          color: _isServiceRunning ? Colors.green : Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '감지 서비스',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _isServiceRunning ? '실행 중' : '중지됨',
                              style: TextStyle(
                                color: _isServiceRunning
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '모니터링 경로',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '/storage/emulated/0/Recordings/Summaries/',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isServiceRunning)
                          ElevatedButton.icon(
                            onPressed: _startService,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('시작'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (_isServiceRunning)
                          ElevatedButton.icon(
                            onPressed: _stopService,
                            icon: const Icon(Icons.stop),
                            label: const Text('중지'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _checkServiceStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('새로고침'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 마크다운 목록 버튼 추가
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MarkdownListScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('변환된 마크다운 보기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 감지된 파일 목록
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '감지된 파일 (${_detectedFiles.length}개)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _detectedFiles.isEmpty
                        ? const Center(child: Text('아직 감지된 파일이 없습니다.'))
                        : ListView.builder(
                            itemCount: _detectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _detectedFiles[index];
                              final fileName = file['file_path']
                                  .split('/')
                                  .last;

                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(fileName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('감지 시간: ${file['detected_at']}'),
                                      Text(
                                        '경로: ${file['file_path']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () {
                                      // TODO: 파일 내용 보기
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('파일 열기: $fileName'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
