import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/call_summary_converter.dart';

class MarkdownService {
  static const String markdownFolderName = 'CallSummaryMarkdowns';

  /// 앱 전용 마크다운 저장 디렉토리 경로 얻기
  static Future<String> getMarkdownDirectory() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String markdownPath = path.join(appDocDir.path, markdownFolderName);

      // 디렉토리가 없으면 생성
      Directory markdownDir = Directory(markdownPath);
      if (!await markdownDir.exists()) {
        await markdownDir.create(recursive: true);
      }

      return markdownPath;
    } catch (e) {
      throw Exception('마크다운 디렉토리 생성 실패: $e');
    }
  }

  /// JSON 파일을 읽어서 마크다운으로 변환 및 저장
  static Future<String> processJsonFile(String jsonFilePath) async {
    try {
      // 1. JSON 파일 읽기
      File jsonFile = File(jsonFilePath);
      if (!await jsonFile.exists()) {
        throw Exception('JSON 파일을 찾을 수 없습니다: $jsonFilePath');
      }

      String jsonContent = await jsonFile.readAsString();

      // 2. 마크다운으로 변환
      String markdownContent =
          CallSummaryConverter.convertCallSummaryToMarkdown(jsonContent);

      // 3. 마크다운 파일명 생성
      String originalFileName = path.basenameWithoutExtension(jsonFilePath);
      String markdownFileName = '$originalFileName.md';

      // 4. 마크다운 파일 저장
      String markdownDir = await getMarkdownDirectory();
      String markdownFilePath = path.join(markdownDir, markdownFileName);

      File markdownFile = File(markdownFilePath);
      await markdownFile.writeAsString(markdownContent);

      print('마크다운 변환 완료: $markdownFilePath');
      return markdownFilePath;
    } catch (e) {
      throw Exception('JSON 파일 처리 실패: $e');
    }
  }

  /// 저장된 마크다운 파일 목록 조회
  static Future<List<Map<String, dynamic>>> getMarkdownFiles() async {
    try {
      String markdownDir = await getMarkdownDirectory();
      Directory directory = Directory(markdownDir);

      if (!await directory.exists()) {
        return [];
      }

      List<FileSystemEntity> files = await directory.list().toList();
      List<Map<String, dynamic>> markdownFiles = [];

      for (FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.md')) {
          FileStat stat = await file.stat();
          String fileName = path.basename(file.path);

          markdownFiles.add({
            'path': file.path,
            'name': fileName,
            'size': stat.size,
            'modified': stat.modified,
          });
        }
      }

      // 수정일 기준 내림차순 정렬
      markdownFiles.sort(
        (a, b) =>
            (b['modified'] as DateTime).compareTo(a['modified'] as DateTime),
      );

      return markdownFiles;
    } catch (e) {
      print('마크다운 파일 목록 조회 오류: $e');
      return [];
    }
  }

  /// 마크다운 파일 내용 읽기
  static Future<String> readMarkdownFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('마크다운 파일을 찾을 수 없습니다: $filePath');
      }

      return await file.readAsString();
    } catch (e) {
      throw Exception('마크다운 파일 읽기 실패: $e');
    }
  }

  /// 마크다운 파일 삭제
  static Future<bool> deleteMarkdownFile(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('마크다운 파일 삭제 오류: $e');
      return false;
    }
  }

  /// 마크다운 파일을 외부 저장소로 내보내기
  static Future<String> exportMarkdownFile(
    String filePath,
    String exportPath,
  ) async {
    try {
      File sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        throw Exception('원본 파일을 찾을 수 없습니다: $filePath');
      }

      String content = await sourceFile.readAsString();
      String fileName = path.basename(filePath);
      String targetPath = path.join(exportPath, fileName);

      File targetFile = File(targetPath);
      await targetFile.writeAsString(content);

      return targetPath;
    } catch (e) {
      throw Exception('마크다운 파일 내보내기 실패: $e');
    }
  }

  /// 통계 정보 조회
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      List<Map<String, dynamic>> files = await getMarkdownFiles();

      int totalFiles = files.length;
      int totalSize = files.fold(0, (sum, file) => sum + (file['size'] as int));

      DateTime? oldestDate;
      DateTime? newestDate;

      if (files.isNotEmpty) {
        oldestDate = files.last['modified'] as DateTime;
        newestDate = files.first['modified'] as DateTime;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'oldestDate': oldestDate,
        'newestDate': newestDate,
      };
    } catch (e) {
      print('통계 정보 조회 오류: $e');
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'oldestDate': null,
        'newestDate': null,
      };
    }
  }

  /// 파일 크기를 읽기 쉬운 형태로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
