import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PathSettingsScreen extends StatefulWidget {
  const PathSettingsScreen({super.key});

  @override
  State<PathSettingsScreen> createState() => _PathSettingsScreenState();
}

class _PathSettingsScreenState extends State<PathSettingsScreen> {
  final TextEditingController _monitoringPathController =
      TextEditingController();
  final TextEditingController _obsidianPathController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _monitoringPathController.dispose();
    _obsidianPathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        _monitoringPathController.text =
            prefs.getString('monitoring_path') ??
            '/storage/emulated/0/Recordings/Summaries/';
        _obsidianPathController.text =
            prefs.getString('obsidian_path') ??
            '/storage/emulated/0/Documents/ObsidianVault';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('설정 로드 실패: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('monitoring_path', _monitoringPathController.text);
      await prefs.setString('obsidian_path', _obsidianPathController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정이 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('경로 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모니터링 경로 설정
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📁 감지할 폴더 경로',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _monitoringPathController,
                            decoration: const InputDecoration(
                              labelText: '통화 요약 파일이 저장되는 폴더',
                              hintText:
                                  '/storage/emulated/0/Recordings/Summaries/',
                              border: OutlineInputBorder(),
                              helperText: '삼성 통화 요약 JSON 파일이 저장되는 경로를 입력하세요.',
                            ),
                            maxLines: 2,
                            minLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Obsidian 경로 설정
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📝 Obsidian Vault 경로',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _obsidianPathController,
                            decoration: const InputDecoration(
                              labelText: 'Obsidian 마크다운 파일을 저장할 폴더',
                              hintText:
                                  '/storage/emulated/0/Documents/ObsidianVault',
                              border: OutlineInputBorder(),
                              helperText:
                                  '변환된 마크다운 파일이 저장될 Obsidian 볼트 경로를 입력하세요.',
                            ),
                            maxLines: 2,
                            minLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('설정 저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 도움말
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                '설정 도움말',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• 감지할 폴더: 삼성 통화 요약 .json 파일이 자동으로 저장되는 폴더입니다.\n'
                            '• Obsidian 경로: 변환된 마크다운 파일이 저장될 폴더입니다.\n'
                            '• 설정 변경 후에는 서비스를 재시작해주세요.',
                            style: TextStyle(fontSize: 14),
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
