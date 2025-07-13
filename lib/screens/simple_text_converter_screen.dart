import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/text_summary_service.dart';

class SimpleTextConverterScreen extends StatefulWidget {
  const SimpleTextConverterScreen({super.key});

  @override
  State<SimpleTextConverterScreen> createState() =>
      _SimpleTextConverterScreenState();
}

class _SimpleTextConverterScreenState extends State<SimpleTextConverterScreen> {
  bool _isLoading = false;
  String? _selectedFilePath;
  String? _outputDirectory;
  Map<String, dynamic>? _fileInfo;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// 권한 상태를 확인하고 필요시 요청합니다
  Future<void> _checkPermissions() async {
    try {
      final manageStorageStatus = await Permission.manageExternalStorage.status;

      if (!manageStorageStatus.isGranted) {
        _showPermissionDialog();
      }
    } catch (e) {
      _showErrorSnackBar('권한 확인 중 오류 발생: $e');
    }
  }

  /// 권한 요청 다이얼로그를 보여줍니다
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('파일 접근 권한 필요'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('통화 녹음 요약 파일에 접근하려면 "모든 파일에 대한 접근 허용" 권한이 필요합니다.'),
            SizedBox(height: 16),
            Text('설정에서 다음과 같이 진행해주세요:'),
            Text('1. 앱 → MemoriaTrace'),
            Text('2. 권한 → 파일 및 미디어'),
            Text('3. "모든 파일에 대한 접근 허용" 활성화'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: _requestPermissions,
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 권한을 요청합니다
  Future<void> _requestPermissions() async {
    Navigator.of(context).pop();

    try {
      final status = await Permission.manageExternalStorage.request();

      if (status.isGranted) {
        _showSuccessSnackBar('권한이 승인되었습니다.');
      } else {
        _showErrorSnackBar('권한이 거부되었습니다. 설정에서 수동으로 활성화해주세요.');
      }
    } catch (e) {
      _showErrorSnackBar('권한 요청 중 오류 발생: $e');
    }
  }

  /// 텍스트 파일을 선택합니다
  Future<void> _selectTextFile() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: TextSummaryService.supportedExtensions
            .map((e) => e.substring(1))
            .toList(),
        dialogTitle: '변환할 통화 녹음 요약 파일을 선택하세요',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        setState(() {
          _selectedFilePath = filePath;
        });

        // 파일 정보 가져오기
        _fileInfo = await TextSummaryService.getFileInfo(filePath);
        setState(() {});

        _showSuccessSnackBar('파일이 선택되었습니다: ${result.files.single.name}');
      }
    } catch (e) {
      _showErrorSnackBar('파일 선택 중 오류 발생: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 출력 폴더를 선택합니다
  Future<void> _selectOutputDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '마크다운 파일을 저장할 폴더를 선택하세요',
      );

      if (result != null) {
        setState(() {
          _outputDirectory = result;
        });
        _showSuccessSnackBar('출력 폴더가 선택되었습니다');
      }
    } catch (e) {
      _showErrorSnackBar('폴더 선택 중 오류 발생: $e');
    }
  }

  /// 마크다운으로 변환합니다
  Future<void> _convertToMarkdown() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('먼저 변환할 텍스트 파일을 선택해주세요.');
      return;
    }

    if (_outputDirectory == null) {
      _showErrorSnackBar('먼저 출력 폴더를 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚀 변환 시작 - UI에서 호출');
      print('선택된 파일: $_selectedFilePath');
      print('출력 디렉토리: $_outputDirectory');

      final success = await TextSummaryService.convertToMarkdown(
        _selectedFilePath!,
        _outputDirectory!,
      );

      if (success) {
        print('✅ 변환 성공 - UI 응답');
        _showSuccessSnackBar('파일이 성공적으로 마크다운으로 변환되었습니다!');
      } else {
        print('❌ 변환 실패 - UI 응답');
        _showErrorSnackBar('마크다운 변환에 실패했습니다.\n로그를 확인해주세요.');
      }
    } catch (e) {
      print('💥 변환 중 예외 발생 - UI: $e');
      _showErrorSnackBar('변환 중 오류 발생:\n$e\n\n로그를 확인해주세요.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 선택사항들을 초기화합니다
  void _reset() {
    setState(() {
      _selectedFilePath = null;
      _outputDirectory = null;
      _fileInfo = null;
    });
    _showInfoSnackBar('선택사항이 초기화되었습니다.');
  }

  /// 성공 메시지를 보여줍니다
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// 정보 메시지를 보여줍니다
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  /// 오류 메시지를 보여줍니다
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통화 녹음 요약 → 마크다운 변환기'),
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
          // 단계 1: 텍스트 파일 선택
          _buildStepCard(
            stepNumber: '1',
            title: '통화 녹음 요약 파일 선택',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('변환할 통화 녹음 요약 텍스트 파일을 선택하세요'),
                const SizedBox(height: 8),
                Text(
                  '지원 형식: ${TextSummaryService.supportedExtensions.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text(
                  '예시: 통화 녹음 이동혁_250710_133659_summary.txt',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectTextFile,
                  icon: const Icon(Icons.description),
                  label: const Text('텍스트 파일 선택'),
                ),
                if (_selectedFilePath != null) ...[
                  const SizedBox(height: 16),
                  _buildSelectedFileInfo(),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 단계 2: 출력 폴더 선택
          _buildStepCard(
            stepNumber: '2',
            title: '출력 폴더 선택',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('마크다운 파일을 저장할 폴더를 선택하세요'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectOutputDirectory,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('출력 폴더 선택'),
                ),
                if (_outputDirectory != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '선택된 출력 폴더:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _outputDirectory!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 단계 3: 변환 실행
          _buildStepCard(
            stepNumber: '3',
            title: '마크다운 변환',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('선택한 텍스트 파일을 Obsidian 마크다운으로 변환합니다'),
                const SizedBox(height: 8),
                const Text(
                  '• 통화 녹음: 상대방별로 하나의 마크다운 파일에 통합\n'
                  '• 일반 음성: 하나의 음성녹음 마크다운 파일에 통합\n'
                  '• 중복 내용은 자동으로 제외됩니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      (_selectedFilePath != null && _outputDirectory != null)
                      ? _convertToMarkdown
                      : null,
                  icon: const Icon(Icons.transform),
                  label: const Text('마크다운으로 변환'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 초기화 버튼
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('초기화'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    if (_fileInfo == null) return const SizedBox.shrink();

    final type = _fileInfo!['type'];
    final contact = _fileInfo!['contact'];
    final date = _fileInfo!['date'];
    final time = _fileInfo!['time'];

    Color cardColor;
    IconData icon;
    String typeText;

    if (type == 'call') {
      cardColor = Colors.blue;
      icon = Icons.phone;
      typeText = '통화 녹음';
    } else if (type == 'voice') {
      cardColor = Colors.green;
      icon = Icons.mic;
      typeText = '일반 음성 녹음';
    } else {
      cardColor = Colors.orange;
      icon = Icons.help_outline;
      typeText = '알 수 없는 형식';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        border: Border.all(color: cardColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor),
              const SizedBox(width: 8),
              Text(
                '선택된 파일 정보',
                style: TextStyle(fontWeight: FontWeight.bold, color: cardColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('파일명: ${_fileInfo!['name']}'),
          Text('크기: ${_fileInfo!['sizeFormatted']}'),
          Text('형식: $typeText'),
          if (contact != null) Text('상대방: $contact'),
          if (date != null)
            Text(
              '날짜: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            ),
          if (time != null) Text('시간: $time'),
        ],
      ),
    );
  }
}
