import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// 음성 파일 변환 서비스
class VoiceNoteService {
  /// 지원하는 오디오 파일 확장자들
  static const List<String> supportedExtensions = [
    '.m4a',
    '.mp3',
    '.wav',
    '.aac',
    '.amr',
    '.3gp',
    '.flac',
    '.ogg',
  ];

  /// 파일이 지원되는 오디오 파일인지 확인합니다
  static bool isSupportedAudioFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// 파일 정보를 가져옵니다
  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();

      return {
        'path': filePath,
        'name': path.basename(filePath),
        'size': stat.size,
        'sizeFormatted': _formatFileSize(stat.size),
        'modified': stat.modified,
        'extension': path.extension(filePath),
      };
    } catch (e) {
      print('파일 정보를 가져오는 중 오류 발생: $e');
      return {};
    }
  }

  /// 파일 크기를 사람이 읽기 쉬운 형태로 포맷합니다
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 음성 파일을 마크다운으로 변환합니다
  static Future<bool> convertToMarkdown(
    String voiceFilePath,
    String outputDirectory,
  ) async {
    try {
      // 지원되는 파일인지 확인
      if (!isSupportedAudioFile(voiceFilePath)) {
        print('지원되지 않는 파일 형식: ${path.extension(voiceFilePath)}');
        return false;
      }

      final fileName = path.basenameWithoutExtension(voiceFilePath);
      final fileInfo = await getFileInfo(voiceFilePath);

      // 마크다운 내용 생성
      final markdownContent = _generateMarkdownContent(fileInfo);

      // Obsidian 경로가 설정되어 있으면 그 경로를 우선 사용
      String finalOutputDir = outputDirectory;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String obsidianPath = prefs.getString('obsidian_path') ?? '';
        if (obsidianPath.isNotEmpty) {
          finalOutputDir = obsidianPath;
        }
      } catch (e) {
        print('SharedPreferences 오류: $e');
      }

      // 마크다운 파일 경로 생성
      final markdownFileName = '${fileName}_voice_note.md';
      final markdownPath = path.join(finalOutputDir, markdownFileName);

      // 마크다운 파일 생성
      final markdownFile = File(markdownPath);
      await markdownFile.parent.create(recursive: true);
      await markdownFile.writeAsString(markdownContent, encoding: utf8);

      print('음성 파일을 마크다운으로 변환 완료: $markdownPath');
      return true;
    } catch (e) {
      print('마크다운 변환 중 오류 발생: $e');
      return false;
    }
  }

  /// 마크다운 내용을 생성합니다
  static String _generateMarkdownContent(Map<String, dynamic> fileInfo) {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];
    final timeStr = now.toIso8601String().split('T')[1].split('.')[0];

    return '''---
type: voice-note
created: ${now.toIso8601String()}
source_file: ${fileInfo['name']}
file_size: ${fileInfo['sizeFormatted']}
file_extension: ${fileInfo['extension']}
modified_date: ${fileInfo['modified']}
tags:
  - voice-recording
  - audio-file
---

# 음성 녹음 - ${fileInfo['name']}

## 파일 정보

- **파일명**: ${fileInfo['name']}
- **크기**: ${fileInfo['sizeFormatted']}
- **형식**: ${fileInfo['extension']}
- **수정일**: ${fileInfo['modified']}
- **원본 경로**: ${fileInfo['path']}

## 변환 정보

- **변환일**: $dateStr $timeStr
- **변환 도구**: MemoriaTrace

## 메모

> 이 파일에 대한 메모를 여기에 추가하세요.

---

*이 문서는 MemoriaTrace에 의해 자동 생성되었습니다.*
''';
  }
}
