import 'dart:io';
import 'dart:convert';

class TestDataGenerator {
  /// 테스트용 샘플 JSON 파일 생성
  static Future<void> createSampleJsonFiles(String targetDirectory) async {
    try {
      Directory dir = Directory(targetDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 예시 1: 요약이 있는 통화 기록
      String sample1 = _getSample1Json();
      File file1 = File('$targetDirectory/통화 요약 114_250711_140713.txt');
      await file1.writeAsString(sample1);

      // 예시 2: 요약이 없는 통화 기록
      String sample2 = _getSample2Json();
      File file2 = File('$targetDirectory/통화 요약 어머니_250711_200029.txt');
      await file2.writeAsString(sample2);

      print('샘플 JSON 파일이 생성되었습니다:');
      print('- ${file1.path}');
      print('- ${file2.path}');
    } catch (e) {
      print('샘플 파일 생성 실패: $e');
    }
  }

  /// 요약이 있는 샘플 JSON 데이터
  static String _getSample1Json() {
    Map<String, dynamic> sample1 = {
      "summary": [
        {
          "aiDataID": 8390,
          "id": 10,
          "summary": jsonEncode([
            {
              "isSafetyFilterData": false,
              "sectionTitle": "신용카드 결제 완료 안내",
              "stringId": -1,
              "summaryList": [
                "카드 일시불 결제 진행을 위해 카드 정보 입력을 요청함.",
                "카드 번호, 유효기간, 주민등록번호 앞 6자리, 카드 비밀번호 앞 2자리를 입력받음.",
                "결제 완료되었으며, 단말기 할부 완납 관련 안내를 제공함.",
              ],
              "timeStamp": 530,
            },
          ]),
          "summaryType": 1,
          "summaryVersion": "1",
        },
      ],
      "speaker": [
        {
          "aiDataID": 8390,
          "id": 30,
          "speaker": jsonEncode({
            "mSpeakerNameMap": {"2": "114"},
          }),
          "speakerVersion": "1",
        },
      ],
      "transcribe_text": {
        "aiDataID": 8390,
        "id": 30,
        "transcriptText":
            "네 여보세요. 안녕하십니까 통화했던 이상욱입니다. 아 네 윤지원님 맞으십니까? 아 죄송합니다. 얼른 복구하고 연락드렸고 카드로 일시불 결제한다 하셨고요. 결제 계좌가 안내 연결하면은 결제할 카드 정보를 멘트에 따라서 휴대폰을 눌러주시면 되겠습니다. 아 네네. 네 네 카드번호를 누르신 후 별표를 눌러주십시오. 입력하신 번호는 4890160397895506 입니다. 맞으면 일 번 틀리면 이 번을 눌러주십시오 신용카드 유효기간 네 자리를 월 두 자리 연도 두 자리 순으로 입력해 주세요. 주민등록번호 앞 6자리 생년월일과 별표를 눌러주세요. 카드 비밀번호 앞에 두 자리를 눌러주십시오. 상담사를 연결해 드리겠습니다. 네. 감사합니다. 단말기 할부는 완납하게 되면 완납한 금액에 대한 환불이나 할부 원본 절대. 네 네 네. 네 아 네 결제 바로 완료되었으니까 걱정 마시고 이용하시면 되겠습니다. 네 아 네 감사합니다. 감사합니다. 이영미였습니다 네",
        "transcriptVersion": "1",
      },
      "summarized_title": jsonEncode({"summarizedTitle": "신용카드 결제 완료 안내"}),
      "transcribe_timestamp": {
        "aiDataID": 8390,
        "id": 30,
        "transcriptExtraInfo": jsonEncode({
          "paragraphInfo":
              "16 1 530 1490 2 2490 17690 1 4650 5610 1 7310 7870 1 12130 13250 2 21270 24950 2 39550 60350 2 66590 71790 2 78130 81650 2 83770 92890 1 88210 88850 1 93550 95470 2 101250 104930 1 103030 106070 2 106670 108350 1 107870 108590",
          "timestamp":
              "111 530 730 730 1490 2490 3330 3330 3810 3810 4690 4690 5610 5690 5850 5850 6490 6490 7250 7250 8010 8250 8610 8610 8970 8970 9330 9330 9930 10170 10570 10570 11090 11090 11490 11490 12170 12170 12890 12890 13250 13250 13450 13530 14170 14250 14650 14730 14970 14970 15370 15370 15730 15730 16010 16010 16450 16450 16850 16850 17690 4650 4890 4970 5610 7310 7870 12130 13250 21270 22110 22110 22550 22630 22790 22870 23630 23630 24950 39550 40510 40510 43010 43010 45510 45510 48010 48010 50510 50510 50630 50630 50910 51070 51790 51790 51950 52030 52390 52390 54030 54030 55670 55670 56270 56270 56430 56430 56990 57150 57390 57550 57670 57670 57950 58030 58350 58350 58510 58510 58830 58830 59270 59270 59830 59830 60350 66590 67870 67870 68110 68270 68990 68990 69710 69870 70670 70670 71790 78130 78490 78490 79170 79170 79810 79810 79930 79930 80450 80450 81650 83770 84530 84530 85010 85010 85890 85890 86810 86810 87730 87730 88610 88610 89010 89010 89570 89570 90010 90090 90650 90650 91090 91090 91370 91370 92010 92010 92250 92250 92570 92570 92890 88210 88850 93550 94210 94210 94880 94880 95470 101250 101370 101370 101650 101650 101890 101970 102170 102170 103010 103010 103290 103290 103610 103610 104090 104090 104930 103030 103910 103910 104790 104950 105110 105190 106070 106670 107550 107550 108350 107870 108590",
        }),
        "transcriptExtraVersion": "1",
      },
      "transcribe_language": {
        "aiDataID": 8390,
        "id": 30,
        "transcribeLanguage": jsonEncode({
          "transcribeLocaleList": [
            {"endTime": 108350, "localeTranscriptTo": "ko-KR", "startTime": 0},
          ],
        }),
        "transcribeLanguageVersion": "1",
      },
      "keyword": [
        {
          "aiDataID": 8390,
          "id": 10,
          "keyword": jsonEncode([
            {"keyword": "카드 결제"},
            {"keyword": "결제 완료"},
          ]),
          "keywordVersion": "1",
        },
      ],
      "recording_sub_info": {
        "file_path":
            "/storage/emulated/0/Recordings/Call/통화 녹음 114_250711_140713.m4a",
        "file_timestamp": "1752212489969",
        "file_datetaken": "1752210544000",
        "file_duration": "109865",
        "file_size": "1780649",
      },
    };

    return jsonEncode(sample1);
  }

  /// 요약이 없는 샘플 JSON 데이터
  static String _getSample2Json() {
    Map<String, dynamic> sample2 = {
      "summary": [],
      "speaker": [
        {
          "aiDataID": 8400,
          "id": 33,
          "speaker": jsonEncode({
            "mSpeakerNameMap": {"2": "어머니"},
          }),
          "speakerVersion": "1",
        },
      ],
      "transcribe_text": {
        "aiDataID": 8400,
        "id": 33,
        "transcriptText":
            "여보세요 엄마 이렇게 얘기하는 거야. 어디에다 대고. 응 엄마 이렇게 얘기하는 거야. 여기다가. 뭐지 말해봐. 여보세요. 말해봐 말해 말해봐. 말해봐 잘 들리네. 잘 들려 어 괜찮은데? 볼륨 올려줘. 오블유 있잖아 아니 아니야 누가? 아니 아니 꺼. 여보세요, 응 말해봐 말해봐 잘 들려 어. 여보세요. 내가 이렇게 말하는 거. 내가 이렇게 말하면 말해 봐.",
        "transcriptVersion": "1",
      },
      "summarized_title": jsonEncode({"summarizedTitle": "어머니와의 통화 테스트"}),
      "transcribe_timestamp": {
        "aiDataID": 8400,
        "id": 33,
        "transcriptExtraInfo": jsonEncode({
          "paragraphInfo":
              "12 2 630 4470 1 1130 3450 1 4550 5430 1 8190 10990 2 10910 13150 1 13390 16430 2 14370 24130 1 25190 29430 2 28350 29550 2 32230 42950 1 32270 35230 1 36830 40350",
          "timestamp":
              "53 630 1310 1310 1990 2230 2510 2510 2950 2950 3590 3590 4190 4190 4470 1130 1610 1610 2090 2330 2650 2650 3010 3010 3450 4550 5430 8190 9630 9630 10990 10910 13150 13390 14230 14230 15070 15630 16430 14370 17050 17050 19730 19810 20810 20810 21810 21890 22490 22490 23090 23170 24130 25190 25670 25670 26550 26550 27430 27510 27990 28310 28630 28630 28950 29190 29430 28350 28710 28710 28990 29230 29550 32230 35510 35510 38790 39430 39990 40150 40790 40790 40950 41030 41750 42630 42950 32270 33310 33310 34310 34310 34470 34470 34870 34870 35230 36830 37190 37190 37430 37430 38590 38590 39750 39750 40350",
        }),
        "transcriptExtraVersion": "1",
      },
      "transcribe_language": {
        "aiDataID": 8400,
        "id": 33,
        "transcribeLanguage": jsonEncode({
          "transcribeLocaleList": [
            {"endTime": 42950, "localeTranscriptTo": "ko-KR", "startTime": 0},
          ],
        }),
        "transcribeLanguageVersion": "1",
      },
      "keyword": [],
      "recording_sub_info": {
        "file_path":
            "/storage/emulated/0/Recordings/Call/통화 녹음 어머니_250711_200029.m4a",
        "file_timestamp": "1752231675002",
        "file_datetaken": "1752231674000",
        "file_duration": "45247",
        "file_size": "733867",
      },
    };

    return jsonEncode(sample2);
  }

  /// 변환 결과 테스트
  static void testConversion() {
    print('=== JSON → 마크다운 변환 테스트 ===\n');

    // 테스트 1: 요약이 있는 경우
    print('테스트 1: 요약이 있는 통화 기록');
    print('--------------------------------');
    String sample1 = _getSample1Json();
    // CallSummaryConverter를 여기서 직접 import할 수 없으므로
    // 실제 테스트는 별도로 수행해야 함
    print('샘플 JSON 길이: ${sample1.length} 문자\n');

    // 테스트 2: 요약이 없는 경우
    print('테스트 2: 요약이 없는 통화 기록');
    print('--------------------------------');
    String sample2 = _getSample2Json();
    print('샘플 JSON 길이: ${sample2.length} 문자\n');

    print('실제 변환 테스트는 앱에서 샘플 파일을 생성한 후 확인하세요.');
  }
}
