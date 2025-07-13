import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/debug_logger.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = DebugLogger.getLogs();
    });
    // 자동으로 맨 아래로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveLogsToFile() async {
    final filePath = await DebugLogger.saveLogsToFile();
    if (filePath != null) {
      _showSnackBar('로그가 저장되었습니다: $filePath', Colors.green);
    } else {
      _showSnackBar('로그 저장에 실패했습니다', Colors.red);
    }
  }

  void _clearLogs() {
    DebugLogger.clearLogs();
    _refreshLogs();
    _showSnackBar('로그가 삭제되었습니다', Colors.blue);
  }

  void _copyAllLogs() {
    final content = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: content));
    _showSnackBar('로그가 클립보드에 복사되었습니다', Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디버그 로그'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLogsToFile,
            tooltip: '파일로 저장',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllLogs,
            tooltip: '복사',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: '삭제',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '로그 ${_logs.length}개 | 실시간 업데이트되지 않습니다. 새로고침 버튼을 눌러주세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      '로그가 없습니다.\n앱을 사용하면 로그가 여기에 표시됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color? bgColor;
                      Color? textColor;

                      // 로그 레벨에 따른 색상 설정
                      if (log.contains('❌')) {
                        bgColor = Colors.red[50];
                        textColor = Colors.red[800];
                      } else if (log.contains('⚠️')) {
                        bgColor = Colors.orange[50];
                        textColor = Colors.orange[800];
                      } else if (log.contains('✅')) {
                        bgColor = Colors.green[50];
                        textColor = Colors.green[800];
                      } else if (log.contains('🎉')) {
                        bgColor = Colors.blue[50];
                        textColor = Colors.blue[800];
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
