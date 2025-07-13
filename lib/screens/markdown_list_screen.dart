import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/markdown_service.dart';

class MarkdownListScreen extends StatefulWidget {
  const MarkdownListScreen({super.key});

  @override
  State<MarkdownListScreen> createState() => _MarkdownListScreenState();
}

class _MarkdownListScreenState extends State<MarkdownListScreen> {
  List<Map<String, dynamic>> _markdownFiles = [];
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadMarkdownFiles();
    _loadStatistics();
  }

  Future<void> _loadMarkdownFiles() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> files =
          await MarkdownService.getMarkdownFiles();
      setState(() {
        _markdownFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('파일 목록 로드 실패: $e')));
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      Map<String, dynamic> stats = await MarkdownService.getStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      print('통계 로드 실패: $e');
    }
  }

  Future<void> _deleteFile(String filePath, String fileName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('\'$fileName\' 파일을 삭제하시겠습니까?'),
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
      bool success = await MarkdownService.deleteMarkdownFile(filePath);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파일이 삭제되었습니다.')));
        _loadMarkdownFiles();
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파일 삭제에 실패했습니다.')));
      }
    }
  }

  void _viewMarkdownFile(String filePath, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MarkdownViewScreen(filePath: filePath, fileName: fileName),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('변환된 마크다운'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadMarkdownFiles();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 통계 정보 카드
          if (_statistics.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '📊 통계 정보',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_statistics['totalFiles'] ?? 0}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text('총 파일 수'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              MarkdownService.formatFileSize(
                                _statistics['totalSize'] ?? 0,
                              ),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text('총 크기'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 파일 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _markdownFiles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '변환된 마크다운 파일이 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'JSON 형태의 통화 요약 파일이 감지되면\n자동으로 마크다운으로 변환됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _markdownFiles.length,
                    itemBuilder: (context, index) {
                      final file = _markdownFiles[index];
                      final fileName = file['name'] as String;
                      final filePath = file['path'] as String;
                      final fileSize = file['size'] as int;
                      final modified = file['modified'] as DateTime;

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.description,
                            color: Colors.blue,
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '크기: ${MarkdownService.formatFileSize(fileSize)}',
                              ),
                              Text('수정: ${_formatDateTime(modified)}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewMarkdownFile(filePath, fileName);
                                  break;
                                case 'delete':
                                  _deleteFile(filePath, fileName);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('보기'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _viewMarkdownFile(filePath, fileName),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MarkdownViewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const MarkdownViewScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<MarkdownViewScreen> createState() => _MarkdownViewScreenState();
}

class _MarkdownViewScreenState extends State<MarkdownViewScreen> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      String content = await MarkdownService.readMarkdownFile(widget.filePath);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _content = '파일을 읽을 수 없습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _content));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('클립보드에 복사되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: '클립보드에 복사',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
    );
  }
}
