import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_logger.dart';

/// 통화 녹음 요약 텍스트 처리 서비스
class TextSummaryService {
  /// 지원하는 텍스트 파일 확장자들
  static const List<String> supportedExtensions = ['.txt', '.md'];

  /// 파일이 지원되는 텍스트 파일인지 확인합니다
  static bool isSupportedTextFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// 파일명에서 정보를 추출합니다
  static Map<String, dynamic> parseFileName(String fileName) {
    final baseName = path.basenameWithoutExtension(fileName);

    // 통화 녹음 패턴: "통화 녹음 이동혁_250710_133659_summary"
    final callPattern = RegExp(r'^통화 녹음 (.+)_(\d{6})_(\d{6})_summary$');
    final callMatch = callPattern.firstMatch(baseName);

    if (callMatch != null) {
      final name = callMatch.group(1)!;
      final dateStr = callMatch.group(2)!; // YYMMDD
      final timeStr = callMatch.group(3)!; // HHMMSS

      return {
        'type': 'call',
        'contact': name,
        'date': _parseDate(dateStr),
        'time': _parseTime(timeStr),
        'dateStr': dateStr,
        'timeStr': timeStr,
        'fileName': fileName,
      };
    }

    // 일반 음성 녹음 패턴: "음성 250707_150008_summary"
    final voicePattern = RegExp(r'^음성 (\d{6})_(\d{6})_summary$');
    final voiceMatch = voicePattern.firstMatch(baseName);

    if (voiceMatch != null) {
      final dateStr = voiceMatch.group(1)!; // YYMMDD
      final timeStr = voiceMatch.group(2)!; // HHMMSS

      return {
        'type': 'voice',
        'contact': null,
        'date': _parseDate(dateStr),
        'time': _parseTime(timeStr),
        'dateStr': dateStr,
        'timeStr': timeStr,
        'fileName': fileName,
      };
    }

    return {
      'type': 'unknown',
      'contact': null,
      'date': null,
      'time': null,
      'dateStr': null,
      'timeStr': null,
      'fileName': fileName,
    };
  }

  /// 날짜 문자열을 파싱합니다 (YYMMDD → DateTime)
  static DateTime? _parseDate(String dateStr) {
    try {
      final year = 2000 + int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final day = int.parse(dateStr.substring(4, 6));
      return DateTime(year, month, day);
    } catch (e) {
      print('날짜 파싱 오류: $e');
      return null;
    }
  }

  /// 시간 문자열을 파싱합니다 (HHMMSS → TimeOfDay)
  static String _parseTime(String timeStr) {
    try {
      final hour = timeStr.substring(0, 2);
      final minute = timeStr.substring(2, 4);
      final second = timeStr.substring(4, 6);
      return '$hour:$minute:$second';
    } catch (e) {
      print('시간 파싱 오류: $e');
      return timeStr;
    }
  }

  /// 파일 정보를 가져옵니다
  static Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      DebugLogger.log('파일 정보 조회: $filePath');
      final file = File(filePath);

      DebugLogger.log('파일 stat 조회 중...');
      final stat = await file.stat();
      DebugLogger.log('✅ 파일 stat 완료');

      final fileName = path.basename(filePath);
      DebugLogger.log('파일명 추출: $fileName');

      DebugLogger.log('파일명 파싱 시작...');
      final parsedInfo = parseFileName(fileName);
      DebugLogger.log('✅ 파일명 파싱 완료: ${parsedInfo['type']}');

      final result = {
        'path': filePath,
        'name': fileName,
        'size': stat.size,
        'sizeFormatted': _formatFileSize(stat.size),
        'modified': stat.modified,
        'extension': path.extension(filePath),
        ...parsedInfo,
      };

      DebugLogger.log('✅ 파일 정보 반환 준비 완료');
      return result;
    } catch (e) {
      DebugLogger.log('❌ 파일 정보를 가져오는 중 오류 발생: $e');
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

  /// 텍스트 파일을 마크다운으로 변환합니다
  static Future<bool> convertToMarkdown(
    String textFilePath,
    String outputDirectory,
  ) async {
    try {
      DebugLogger.log('=== 변환 시작 ===');
      DebugLogger.log('입력 파일: $textFilePath');
      DebugLogger.log('출력 디렉토리: $outputDirectory');

      // 지원되는 파일인지 확인
      if (!isSupportedTextFile(textFilePath)) {
        DebugLogger.log('❌ 지원되지 않는 파일 형식: ${path.extension(textFilePath)}');
        return false;
      }
      DebugLogger.log('✅ 파일 형식 검증 통과');

      // 파일이 존재하는지 확인
      final file = File(textFilePath);
      DebugLogger.log('파일 객체 생성: ${file.path}');

      bool fileExists;
      try {
        fileExists = await file.exists();
        DebugLogger.log('파일 존재 여부: $fileExists');
      } catch (e) {
        DebugLogger.log('❌ 파일 존재 확인 중 오류: $e');
        return false;
      }

      if (!fileExists) {
        DebugLogger.log('❌ 파일이 존재하지 않습니다: $textFilePath');
        return false;
      }
      DebugLogger.log('✅ 파일 존재 확인');

      DebugLogger.log('파일 정보 조회 시작...');
      final fileInfo = await getFileInfo(textFilePath);
      if (fileInfo.isEmpty) {
        DebugLogger.log('❌ 파일 정보를 가져올 수 없습니다');
        return false;
      }
      DebugLogger.log('✅ 파일 정보 획득: ${fileInfo['name']}');
      DebugLogger.log('   파일 타입: ${fileInfo['type']}');
      DebugLogger.log('   상대방: ${fileInfo['contact'] ?? '미확인'}');
      DebugLogger.log('   날짜: ${fileInfo['dateStr'] ?? '미확인'}');
      DebugLogger.log('   시간: ${fileInfo['timeStr'] ?? '미확인'}');

      String textContent;
      try {
        DebugLogger.log('파일 읽기 시작...');

        // 먼저 바이트로 읽어서 BOM 확인
        final bytes = await file.readAsBytes();
        DebugLogger.log('파일 크기: ${bytes.length} 바이트');

        if (bytes.length >= 2) {
          final bom = bytes.take(2).toList();
          DebugLogger.log('BOM 확인: [${bom[0]}, ${bom[1]}]');

          // UTF-16 LE BOM: FF FE
          if (bom[0] == 0xFF && bom[1] == 0xFE) {
            try {
              // UTF-16 LE로 디코딩
              final utf16Bytes = bytes.skip(2).toList(); // BOM 제거
              final codeUnits = <int>[];
              for (int i = 0; i < utf16Bytes.length; i += 2) {
                if (i + 1 < utf16Bytes.length) {
                  final codeUnit = utf16Bytes[i] | (utf16Bytes[i + 1] << 8);
                  codeUnits.add(codeUnit);
                }
              }
              textContent = String.fromCharCodes(codeUnits);
              DebugLogger.log('✅ UTF-16 LE 디코딩 성공');
            } catch (utf16Error) {
              DebugLogger.log('⚠️ UTF-16 LE 디코딩 실패: $utf16Error');
              rethrow;
            }
          }
          // UTF-16 BE BOM: FE FF
          else if (bom[0] == 0xFE && bom[1] == 0xFF) {
            try {
              // UTF-16 BE로 디코딩
              final utf16Bytes = bytes.skip(2).toList(); // BOM 제거
              final codeUnits = <int>[];
              for (int i = 0; i < utf16Bytes.length; i += 2) {
                if (i + 1 < utf16Bytes.length) {
                  final codeUnit = (utf16Bytes[i] << 8) | utf16Bytes[i + 1];
                  codeUnits.add(codeUnit);
                }
              }
              textContent = String.fromCharCodes(codeUnits);
              DebugLogger.log('✅ UTF-16 BE 디코딩 성공');
            } catch (utf16Error) {
              DebugLogger.log('⚠️ UTF-16 BE 디코딩 실패: $utf16Error');
              rethrow;
            }
          }
          // UTF-8 BOM: EF BB BF
          else if (bytes.length >= 3 &&
              bom[0] == 0xEF &&
              bom[1] == 0xBB &&
              bytes[2] == 0xBF) {
            try {
              textContent = utf8.decode(bytes.skip(3).toList()); // BOM 제거
              DebugLogger.log('✅ UTF-8 (with BOM) 디코딩 성공');
            } catch (utf8Error) {
              DebugLogger.log('⚠️ UTF-8 BOM 디코딩 실패: $utf8Error');
              rethrow;
            }
          }
          // BOM 없음 - 일반적인 인코딩 시도
          else {
            DebugLogger.log('BOM 없음, 일반 인코딩 시도');

            // UTF-8 시도
            try {
              textContent = utf8.decode(bytes);
              DebugLogger.log('✅ UTF-8 (without BOM) 디코딩 성공');
            } catch (utf8Error) {
              DebugLogger.log('⚠️ UTF-8 디코딩 실패: $utf8Error');

              // Latin1로 시도
              try {
                textContent = latin1.decode(bytes);
                DebugLogger.log('✅ Latin1 디코딩 성공');
              } catch (latin1Error) {
                DebugLogger.log('❌ 모든 인코딩 시도 실패');
                throw Exception('지원되지 않는 파일 인코딩');
              }
            }
          }
        } else {
          throw Exception('파일이 너무 작습니다');
        }
      } catch (e) {
        DebugLogger.log('❌ 파일 읽기 완전 실패: $e');
        return false;
      }

      if (textContent.trim().isEmpty) {
        DebugLogger.log('❌ 파일 내용이 비어있습니다');
        return false;
      }

      // 파일 내용 미리보기 (처음 100자)
      final preview = textContent.length > 100
          ? '${textContent.substring(0, 100)}...'
          : textContent;
      DebugLogger.log('파일 내용 미리보기: "$preview"');
      DebugLogger.log('✅ 파일 내용 읽기 완료 (${textContent.length} 문자)');

      // Obsidian 경로가 설정되어 있으면 그 경로를 우선 사용
      String finalOutputDir = outputDirectory;
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String obsidianPath = prefs.getString('obsidian_path') ?? '';
        if (obsidianPath.isNotEmpty) {
          finalOutputDir = obsidianPath;
          print('✅ Obsidian 경로 사용: $finalOutputDir');
        } else {
          print('⚠️ Obsidian 경로 미설정, 기본 출력 경로 사용: $finalOutputDir');
        }
      } catch (e) {
        print('⚠️ SharedPreferences 오류: $e');
      }

      // 출력 디렉토리 유효성 검사
      if (finalOutputDir.trim().isEmpty) {
        print('❌ 출력 디렉토리가 설정되지 않았습니다');
        return false;
      }
      print('✅ 최종 출력 디렉토리: $finalOutputDir');

      // 기존 마크다운 파일이 있는지 확인하고 내용 추가 또는 새 파일 생성
      final success = await _processMarkdownFile(
        fileInfo,
        textContent,
        finalOutputDir,
      );

      if (success) {
        print('🎉 텍스트 파일을 마크다운으로 변환 완료');
        return true;
      } else {
        print('❌ 마크다운 변환 실패');
        return false;
      }
    } catch (e) {
      print('💥 마크다운 변환 중 치명적 오류 발생: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return false;
    }
  }

  /// 마크다운 파일 처리 (기존 파일에 추가 또는 새 파일 생성)
  static Future<bool> _processMarkdownFile(
    Map<String, dynamic> fileInfo,
    String textContent,
    String outputDir,
  ) async {
    try {
      print('=== 마크다운 파일 처리 시작 ===');
      final type = fileInfo['type'];
      final contact = fileInfo['contact'];

      String markdownFileName;
      if (type == 'call' && contact != null) {
        // 통화 녹음: "통화녹음_이동혁.md"
        markdownFileName = '통화녹음_$contact.md';
      } else if (type == 'voice') {
        // 일반 음성: "음성녹음.md"
        markdownFileName = '음성녹음.md';
      } else {
        // 알 수 없는 형식: 원본 파일명 사용
        markdownFileName =
            '${path.basenameWithoutExtension(fileInfo['name'])}.md';
      }

      print('✅ 마크다운 파일명 결정: $markdownFileName');
      print('   파일 타입: $type');
      print('   연락처: ${contact ?? '없음'}');

      // 출력 디렉토리가 존재하는지 확인하고 생성
      final outputDirectory = Directory(outputDir);
      if (!await outputDirectory.exists()) {
        print('📁 출력 디렉토리 생성 중: $outputDir');
        try {
          await outputDirectory.create(recursive: true);
          print('✅ 디렉토리 생성 완료');
        } catch (e) {
          print('❌ 디렉토리 생성 실패: $e');
          return false;
        }
      } else {
        print('✅ 출력 디렉토리 존재 확인');
      }

      final markdownPath = path.join(outputDir, markdownFileName);
      final markdownFile = File(markdownPath);
      print('📄 마크다운 파일 경로: $markdownPath');

      // 기존 파일이 있는지 확인
      String existingContent = '';
      bool isNewFile = false;

      if (await markdownFile.exists()) {
        print('📖 기존 마크다운 파일 발견');
        try {
          existingContent = await markdownFile.readAsString(encoding: utf8);
          print('✅ 기존 파일 읽기 완료 (${existingContent.length} 문자)');
        } catch (e) {
          print('❌ 기존 파일 읽기 오류: $e');
          // 기존 파일을 읽을 수 없으면 새 파일로 처리
          isNewFile = true;
        }

        if (!isNewFile) {
          // 중복 확인: 같은 날짜/시간의 내용이 이미 있는지 체크
          final dateTimePattern =
              '${fileInfo['dateStr']}_${fileInfo['timeStr']}';
          if (existingContent.contains(dateTimePattern)) {
            print('⚠️ 이미 존재하는 내용입니다: $dateTimePattern');
            return true; // 중복이므로 성공으로 처리
          }
          print('✅ 중복 내용 없음, 추가 진행');
        }
      } else {
        print('📝 새 마크다운 파일 생성 예정');
        isNewFile = true;
      }

      // 새로운 내용 생성
      print('📝 마크다운 내용 생성 중...');
      final newContent = _generateMarkdownContent(fileInfo, textContent);
      print('✅ 마크다운 내용 생성 완료 (${newContent.length} 문자)');

      String finalContent;
      if (isNewFile || existingContent.trim().isEmpty) {
        // 새 파일 생성 - 헤더 포함
        print('📄 새 파일 형식으로 생성');
        final header = _generateMarkdownHeader(fileInfo);
        finalContent = header + newContent;
      } else {
        // 기존 파일에 내용 추가
        print('📖 기존 파일에 내용 추가');
        finalContent = '$existingContent\n---\n\n$newContent';
      }

      // 파일 저장
      print('💾 파일 저장 중...');
      try {
        await markdownFile.writeAsString(finalContent, encoding: utf8);
        print('🎉 마크다운 파일 저장 완료: $markdownPath');
        print('   최종 파일 크기: ${finalContent.length} 문자');
        return true;
      } catch (writeError) {
        print('❌ 파일 쓰기 오류: $writeError');
        return false;
      }
    } catch (e) {
      print('💥 마크다운 파일 처리 중 치명적 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return false;
    }
  }

  /// 마크다운 헤더를 생성합니다 (새 파일용)
  static String _generateMarkdownHeader(Map<String, dynamic> fileInfo) {
    final type = fileInfo['type'];
    final contact = fileInfo['contact'];

    String title;
    List<String> tags;

    if (type == 'call' && contact != null) {
      title = '통화 녹음 - $contact';
      tags = ['통화녹음', contact, '요약'];
    } else if (type == 'voice') {
      title = '음성 녹음';
      tags = ['음성녹음', '회의', '요약'];
    } else {
      title = '녹음 요약';
      tags = ['녹음', '요약'];
    }

    return '''---
type: summary-note
title: $title
created: ${DateTime.now().toIso8601String()}
tags:
${tags.map((tag) => '  - $tag').join('\n')}
---

# $title

''';
  }

  /// 마크다운 내용을 생성합니다
  static String _generateMarkdownContent(
    Map<String, dynamic> fileInfo,
    String textContent,
  ) {
    final date = fileInfo['date'];
    final time = fileInfo['time'];
    final dateStr = fileInfo['dateStr'];
    final timeStr = fileInfo['timeStr'];
    final contact = fileInfo['contact'];

    String dateTimeString = '';
    if (date != null) {
      dateTimeString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $time';
    }

    String subtitle;
    if (contact != null) {
      subtitle = '## 📞 $contact - $dateTimeString';
    } else {
      subtitle = '## 🎙️ $dateTimeString';
    }

    // 키워드와 요약 부분 파싱
    final lines = textContent.split('\n');
    String keywords = '';
    String summary = '';
    bool inSummary = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line == '키워드') {
        // 다음 줄이 키워드 내용
        if (i + 1 < lines.length) {
          keywords = lines[i + 1].trim();
        }
      } else if (line == '요약') {
        inSummary = true;
        continue;
      } else if (inSummary && line.isNotEmpty) {
        summary += '$line\n';
      }
    }

    return '''$subtitle

**파일명**: `${fileInfo['name']}`  
**식별자**: `${dateStr}_$timeStr`

### 🏷️ 키워드
$keywords

### 📝 요약 내용

$summary

''';
  }
}
