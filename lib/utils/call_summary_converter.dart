import 'dart:convert';

class CallSummaryConverter {
  /// 삼성 통화 요약 JSON을 옵시디언 마크다운으로 변환
  static String convertCallSummaryToMarkdown(String jsonString) {
    try {
      // 1. 전체 JSON 파싱
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // 2. 핵심 데이터 추출
      String caller = _extractCaller(jsonData);
      String callDate = _extractCallDate(jsonData);
      String title = _extractTitle(jsonData);
      List<String> keywords = _extractKeywords(jsonData);
      List<String> summaryPoints = _extractSummaryPoints(jsonData);
      String transcript = _extractTranscript(jsonData);

      // 3. 마크다운 텍스트 조합
      return _buildMarkdown(
        caller: caller,
        callDate: callDate,
        title: title,
        keywords: keywords,
        summaryPoints: summaryPoints,
        transcript: transcript,
      );
    } catch (e) {
      // 4. 오류 처리
      return _buildErrorMarkdown(e.toString(), jsonString);
    }
  }

  /// 통화 상대방 추출
  static String _extractCaller(Map<String, dynamic> jsonData) {
    try {
      List<dynamic>? speakers = jsonData['speaker'];
      if (speakers != null && speakers.isNotEmpty) {
        String speakerJson = speakers[0]['speaker'];
        Map<String, dynamic> speakerData = jsonDecode(speakerJson);
        Map<String, dynamic>? nameMap = speakerData['mSpeakerNameMap'];

        if (nameMap != null && nameMap.isNotEmpty) {
          // 첫 번째 값을 반환 (보통 상대방 이름)
          return nameMap.values.first.toString();
        }
      }
    } catch (e) {
      print('통화 상대방 추출 오류: $e');
    }
    return '알 수 없음';
  }

  /// 통화 날짜 추출 및 형식 변환
  static String _extractCallDate(Map<String, dynamic> jsonData) {
    try {
      Map<String, dynamic>? recordingInfo = jsonData['recording_sub_info'];
      if (recordingInfo != null) {
        String? timestampStr = recordingInfo['file_datetaken'];
        if (timestampStr != null) {
          int timestamp = int.parse(timestampStr);
          DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
        }
      }
    } catch (e) {
      print('통화 날짜 추출 오류: $e');
    }
    return DateTime.now().toString().split(' ')[0]; // 기본값으로 오늘 날짜
  }

  /// 요약 제목 추출
  static String _extractTitle(Map<String, dynamic> jsonData) {
    try {
      String? titleJson = jsonData['summarized_title'];
      if (titleJson != null) {
        Map<String, dynamic> titleData = jsonDecode(titleJson);
        String? title = titleData['summarizedTitle'];
        if (title != null && title.isNotEmpty) {
          // 너무 긴 제목은 100자로 제한
          if (title.length > 100) {
            return '${title.substring(0, 97)}...';
          }
          return title;
        }
      }
    } catch (e) {
      print('요약 제목 추출 오류: $e');
    }
    return '통화 기록';
  }

  /// 키워드 추출
  static List<String> _extractKeywords(Map<String, dynamic> jsonData) {
    try {
      List<dynamic>? keywordArray = jsonData['keyword'];
      if (keywordArray != null && keywordArray.isNotEmpty) {
        String keywordJson = keywordArray[0]['keyword'];
        List<dynamic> keywordList = jsonDecode(keywordJson);

        return keywordList
            .map((item) => item['keyword'].toString())
            .where((keyword) => keyword.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('키워드 추출 오류: $e');
    }
    return [];
  }

  /// 세 줄 요약 추출
  static List<String> _extractSummaryPoints(Map<String, dynamic> jsonData) {
    try {
      List<dynamic>? summaryArray = jsonData['summary'];
      if (summaryArray != null && summaryArray.isNotEmpty) {
        String summaryJson = summaryArray[0]['summary'];
        List<dynamic> summaryData = jsonDecode(summaryJson);

        if (summaryData.isNotEmpty) {
          List<dynamic>? summaryList = summaryData[0]['summaryList'];
          if (summaryList != null) {
            return summaryList
                .map((item) => item.toString())
                .where((summary) => summary.isNotEmpty)
                .toList();
          }
        }
      }
    } catch (e) {
      print('요약 추출 오류: $e');
    }
    return [];
  }

  /// 전체 통화 내용 추출
  static String _extractTranscript(Map<String, dynamic> jsonData) {
    try {
      Map<String, dynamic>? transcribeText = jsonData['transcribe_text'];
      if (transcribeText != null) {
        String? transcript = transcribeText['transcriptText'];
        if (transcript != null && transcript.isNotEmpty) {
          return transcript.trim();
        }
      }
    } catch (e) {
      print('통화 내용 추출 오류: $e');
    }
    return '통화 내용을 찾을 수 없습니다.';
  }

  /// 마크다운 텍스트 생성
  static String _buildMarkdown({
    required String caller,
    required String callDate,
    required String title,
    required List<String> keywords,
    required List<String> summaryPoints,
    required String transcript,
  }) {
    StringBuffer markdown = StringBuffer();

    // YAML Frontmatter
    markdown.writeln('---');
    markdown.writeln('caller: "$caller"');
    markdown.writeln('date: $callDate');

    // 태그 생성 (통화기록 + 키워드)
    List<String> tags = ['통화기록'];
    tags.addAll(keywords);
    if (tags.isNotEmpty) {
      markdown.writeln('tags:');
      for (String tag in tags) {
        markdown.writeln('  - "$tag"');
      }
    }
    markdown.writeln('---');
    markdown.writeln();

    // 제목
    markdown.writeln('# $title');
    markdown.writeln();

    // 통화 정보
    markdown.writeln('## 📞 통화 정보');
    markdown.writeln('- **상대방:** $caller');
    markdown.writeln('- **날짜:** $callDate');
    if (keywords.isNotEmpty) {
      markdown.writeln('- **키워드:** ${keywords.join(', ')}');
    }
    markdown.writeln();

    // 세 줄 요약 (있는 경우에만)
    if (summaryPoints.isNotEmpty) {
      markdown.writeln('## 📝 요약');
      for (int i = 0; i < summaryPoints.length; i++) {
        markdown.writeln('${i + 1}. ${summaryPoints[i]}');
      }
      markdown.writeln();
    }

    // 전체 통화 내용
    markdown.writeln('## 💬 전체 대화');
    markdown.writeln('```');
    markdown.writeln(transcript);
    markdown.writeln('```');

    return markdown.toString();
  }

  /// 오류 발생 시 기본 마크다운 생성
  static String _buildErrorMarkdown(String error, String originalJson) {
    StringBuffer markdown = StringBuffer();

    markdown.writeln('---');
    markdown.writeln('caller: "파싱 오류"');
    markdown.writeln('date: ${DateTime.now().toString().split(' ')[0]}');
    markdown.writeln('tags:');
    markdown.writeln('  - "통화기록"');
    markdown.writeln('  - "파싱오류"');
    markdown.writeln('---');
    markdown.writeln();

    markdown.writeln('# 통화 기록 파싱 오류');
    markdown.writeln();

    markdown.writeln('## ⚠️ 오류 정보');
    markdown.writeln('JSON 파싱 중 오류가 발생했습니다:');
    markdown.writeln('```');
    markdown.writeln(error);
    markdown.writeln('```');
    markdown.writeln();

    markdown.writeln('## 📄 원본 JSON');
    markdown.writeln('```json');
    // JSON을 예쁘게 포맷팅 시도
    try {
      Map<String, dynamic> jsonData = jsonDecode(originalJson);
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      markdown.writeln(encoder.convert(jsonData));
    } catch (e) {
      markdown.writeln(originalJson);
    }
    markdown.writeln('```');

    return markdown.toString();
  }

  /// 파일에서 JSON을 읽어서 마크다운으로 변환
  static Future<String> convertFileToMarkdown(String filePath) async {
    try {
      // 파일 읽기는 별도 함수에서 처리
      // 여기서는 파일 경로만 받아서 처리할 예정
      return 'TODO: 파일 읽기 구현 필요 - $filePath';
    } catch (e) {
      return _buildErrorMarkdown('파일 읽기 오류: $e', '');
    }
  }
}
