import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/obsidian_writer.dart';
import 'dart:io';

class ObsidianSettingsScreen extends StatefulWidget {
  const ObsidianSettingsScreen({super.key});

  @override
  State<ObsidianSettingsScreen> createState() => _ObsidianSettingsScreenState();
}

class _ObsidianSettingsScreenState extends State<ObsidianSettingsScreen> {
  final TextEditingController _pathController = TextEditingController();
  String _currentPath = '';
  Map<String, dynamic> _statistics = {};
  List<String> _processedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStatistics();
    _loadProcessedFiles();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String savedPath = prefs.getString('obsidian_path') ?? '';

      if (savedPath.isEmpty) {
        // 기본 경로 설정
        savedPath = await _getDefaultObsidianPath();
      }

      setState(() {
        _currentPath = savedPath;
        _pathController.text = savedPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('설정 로드 오류: $e');
    }
  }

  Future<String> _getDefaultObsidianPath() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      return '${appDocDir.path}/ObsidianVault';
    } catch (e) {
      return '/storage/emulated/0/Documents/ObsidianVault';
    }
  }

  Future<void> _saveSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('obsidian_path', _pathController.text);

      setState(() => _currentPath = _pathController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('옵시디언 경로가 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 저장 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadStatistics() async {
    try {
      Map<String, dynamic> stats =
          await ObsidianWriter.getProcessingStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      print('통계 로드 실패: $e');
    }
  }

  Future<void> _loadProcessedFiles() async {
    try {
      List<String> files = await ObsidianWriter.getProcessedFiles();
      setState(() => _processedFiles = files);
    } catch (e) {
      print('처리된 파일 목록 로드 실패: $e');
    }
  }

  Future<void> _testObsidianPath() async {
    String testPath = _pathController.text.trim();
    if (testPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('경로를 입력해주세요.')));
      return;
    }

    try {
      Directory testDir = Directory(testPath);

      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }

      // 테스트 파일 생성
      String testFilePath = '$testPath/test_connection.md';
      File testFile = File(testFilePath);
      await testFile.writeAsString(
        '# 연결 테스트\n\n이 파일은 MemoriaTrace에서 생성된 테스트 파일입니다.\n생성 시간: ${DateTime.now()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연결 테스트 성공! 테스트 파일이 생성되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 테스트 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _clearProcessedRecords() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('처리 기록 삭제'),
        content: const Text(
          '모든 처리 기록을 삭제하시겠습니까?\n삭제하면 이전에 처리된 파일들이 다시 처리될 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ObsidianWriter.clearAllProcessedRecords();
        _loadStatistics();
        _loadProcessedFiles();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 처리 기록이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 기록 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('옵시디언 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 경로 설정 섹션
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📁 옵시디언 저장 경로',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pathController,
                            decoration: const InputDecoration(
                              labelText: '옵시디언 볼트 경로',
                              hintText:
                                  '/storage/emulated/0/Documents/ObsidianVault',
                              border: OutlineInputBorder(),
                              helperText: '통화 기록이 저장될 옵시디언 볼트의 경로를 입력하세요.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveSettings,
                                  icon: const Icon(Icons.save),
                                  label: const Text('저장'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _testObsidianPath,
                                  icon: const Icon(Icons.wifi_tethering),
                                  label: const Text('연결 테스트'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 통계 정보 섹션
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 처리 통계',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${_statistics['total_processed'] ?? 0}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Text('처리된 파일'),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    _currentPath.isNotEmpty ? '설정됨' : '미설정',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: _currentPath.isNotEmpty
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Text('저장 경로'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _clearProcessedRecords,
                            icon: const Icon(
                              Icons.clear_all,
                              color: Colors.red,
                            ),
                            label: const Text(
                              '모든 처리 기록 삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 처리된 파일 목록 섹션
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '📄 처리된 파일 목록',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                onPressed: () {
                                  _loadProcessedFiles();
                                  _loadStatistics();
                                },
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_processedFiles.isEmpty)
                            const Center(
                              child: Text(
                                '아직 처리된 파일이 없습니다.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _processedFiles.length,
                              itemBuilder: (context, index) {
                                String filename = _processedFiles[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  title: Text(filename),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await ObsidianWriter.removeProcessedRecord(
                                          filename,
                                        );
                                        _loadProcessedFiles();
                                        _loadStatistics();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '$filename 처리 기록이 삭제되었습니다.',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('삭제 실패: $e')),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
