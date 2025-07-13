import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class ObsidianSettingsScreen extends StatefulWidget {
  const ObsidianSettingsScreen({super.key});

  @override
  State<ObsidianSettingsScreen> createState() => _ObsidianSettingsScreenState();
}

class _ObsidianSettingsScreenState extends State<ObsidianSettingsScreen> {
  final TextEditingController _pathController = TextEditingController();
  String _currentPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

      setState(() {
        _currentPath = savedPath;
        _pathController.text = savedPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('설정 로드 중 오류: $e');
    }
  }

  Future<void> _selectObsidianPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Obsidian 볼트 폴더를 선택하세요',
      );

      if (result != null) {
        setState(() {
          _currentPath = result;
          _pathController.text = result;
        });
        await _savePath(result);
        _showSuccessSnackBar('Obsidian 경로가 설정되었습니다');
      }
    } catch (e) {
      _showErrorSnackBar('경로 선택 중 오류: $e');
    }
  }

  Future<void> _savePath(String path) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('obsidian_path', path);
    } catch (e) {
      _showErrorSnackBar('경로 저장 중 오류: $e');
    }
  }

  void _clearPath() async {
    setState(() {
      _currentPath = '';
      _pathController.text = '';
    });
    await _savePath('');
    _showInfoSnackBar('Obsidian 경로가 초기화되었습니다');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obsidian 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Obsidian 볼트 경로',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '변환된 마크다운 파일을 저장할 Obsidian 볼트 폴더를 설정하세요.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: '현재 설정된 경로',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_open),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectObsidianPath,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('폴더 선택'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _currentPath.isNotEmpty ? _clearPath : null,
                        icon: const Icon(Icons.clear),
                        label: const Text('초기화'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '설정 가이드',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Obsidian이 설치되어 있어야 합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Obsidian 볼트(노트가 저장되는 폴더)를 미리 생성해두세요.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. 위의 "폴더 선택" 버튼을 눌러 볼트 폴더를 선택하세요.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '4. 변환된 마크다운 파일은 선택한 폴더에 저장됩니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentPath.isNotEmpty
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _currentPath.isNotEmpty
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '설정 상태',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _currentPath.isNotEmpty
                          ? Colors.green[50]
                          : Colors.orange[50],
                      border: Border.all(
                        color: _currentPath.isNotEmpty
                            ? Colors.green
                            : Colors.orange,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentPath.isNotEmpty
                          ? '✓ Obsidian 경로가 설정되었습니다'
                          : '⚠ Obsidian 경로를 설정해주세요',
                      style: TextStyle(
                        color: _currentPath.isNotEmpty
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
