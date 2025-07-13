import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class MarkdownListScreen extends StatefulWidget {
  const MarkdownListScreen({super.key});

  @override
  State<MarkdownListScreen> createState() => _MarkdownListScreenState();
}

class _MarkdownListScreenState extends State<MarkdownListScreen> {
  List<FileSystemEntity> _markdownFiles = [];
  bool _isLoading = true;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _loadMarkdownFiles();
  }

  Future<void> _loadMarkdownFiles() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentPath = prefs.getString('obsidian_path') ?? '';

      if (_currentPath.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final directory = Directory(_currentPath);
      if (await directory.exists()) {
        final files = await directory
            .list(recursive: true)
            .where((entity) => entity is File && entity.path.endsWith('.md'))
            .toList();

        // 파일 수정 시간 기준으로 정렬 (최신순)
        files.sort((a, b) {
          final aStat = File(a.path).statSync();
          final bStat = File(b.path).statSync();
          return bStat.modified.compareTo(aStat.modified);
        });

        setState(() {
          _markdownFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('설정된 Obsidian 경로가 존재하지 않습니다');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('파일 로드 중 오류: $e');
    }
  }

  String _getFileName(String fullPath) {
    return fullPath.split(Platform.pathSeparator).last;
  }

  String _getRelativePath(String fullPath) {
    if (_currentPath.isEmpty) return fullPath;
    return fullPath
        .replaceFirst(_currentPath, '')
        .replaceFirst(Platform.pathSeparator, '');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      _showSuccessSnackBar('파일이 삭제되었습니다');
      _loadMarkdownFiles(); // 목록 새로고침
    } catch (e) {
      _showErrorSnackBar('파일 삭제 중 오류: $e');
    }
  }

  void _showDeleteConfirmDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('정말로 "${_getFileName(filePath)}" 파일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFile(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MarkdownViewerScreen(
              fileName: _getFileName(filePath),
              content: content,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('파일 열기 중 오류: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
        title: const Text('변환된 마크다운 파일'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadMarkdownFiles,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPath.isEmpty) {
      return _buildNoPathMessage();
    }

    if (_markdownFiles.isEmpty) {
      return _buildNoFilesMessage();
    }

    return _buildFileList();
  }

  Widget _buildNoPathMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Obsidian 경로가 설정되지 않았습니다',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '설정 탭에서 Obsidian 볼트 경로를 설정해주세요',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilesMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '변환된 마크다운 파일이 없습니다',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '파일 변환 탭에서 음성 파일을 변환해보세요',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.folder, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '경로: $_currentPath',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '총 ${_markdownFiles.length}개 파일',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _markdownFiles.length,
            itemBuilder: (context, index) {
              final file = File(_markdownFiles[index].path);
              final stat = file.statSync();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.green),
                  title: Text(
                    _getFileName(file.path),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getRelativePath(file.path)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatFileSize(stat.size),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatDateTime(stat.modified),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'open':
                          _openFile(file.path);
                          break;
                        case 'delete':
                          _showDeleteConfirmDialog(file.path);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new),
                            SizedBox(width: 8),
                            Text('열기'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _openFile(file.path),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MarkdownViewerScreen extends StatelessWidget {
  final String fileName;
  final String content;

  const MarkdownViewerScreen({
    super.key,
    required this.fileName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}
