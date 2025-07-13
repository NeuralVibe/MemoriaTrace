# MemoriaTrace

MemoriaTrace는 삼성 통화 요약 파일을 자동으로 감지하고 Obsidian 호환 마크다운으로 변환하는 Flutter 앱입니다.

## 핵심 기능

- 📁 **자동 파일 감지**: 삼성 통화 요약 JSON 파일 실시간 모니터링
- 🔄 **백그라운드 서비스**: 지속적인 파일 감지 및 자동 처리
- 📝 **마크다운 변환**: Obsidian 호환 형식으로 자동 변환
- 🚫 **중복 방지**: SQLite 기반 처리 기록 관리
- ⚙️ **설정 관리**: Obsidian 볼트 경로 설정 및 통계 확인
- 📊 **통계 및 관리**: 처리된 파일 목록 및 통계 정보

## 개발 환경 설정

### 필수 요구사항

1. **JDK 17**
2. **Flutter SDK** (최신 안정 버전)
3. **Android Studio** 또는 **VS Code** (Flutter 플러그인 포함)

### 설치 및 설정

1. **Flutter SDK 설치**

   ```bash
   # Flutter 공식 웹사이트에서 다운로드: https://flutter.dev/docs/get-started/install
   ```

2. **프로젝트 의존성 설치**

   ```bash
   cd MemoriaTrace
   flutter pub get
   ```

3. **Android 에뮬레이터 또는 실제 기기 연결**

4. **앱 실행**
   ```bash
   flutter run
   ```

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 및 권한 관리
├── services/
│   ├── file_monitoring_service.dart   # 백그라운드 파일 감지 서비스
│   ├── obsidian_writer.dart          # 중복 방지 및 Obsidian 연동
│   └── markdown_service.dart         # 마크다운 파일 관리
├── screens/
│   ├── service_control_screen.dart    # 서비스 제어 메인 화면
│   ├── markdown_list_screen.dart      # 변환된 파일 목록
│   └── obsidian_settings_screen.dart  # Obsidian 설정 관리
└── utils/
    ├── call_summary_converter.dart    # JSON → 마크다운 변환기
    └── test_data_generator.dart       # 테스트 데이터 생성
```

## 사용된 라이브러리

### 핵심 기능

- `flutter_background_service`: 백그라운드 파일 감지 서비스
- `sqflite`: 중복 파일 처리를 위한 로컬 데이터베이스
- `shared_preferences`: 설정 데이터 저장

### 파일 시스템 및 권한

- `path_provider`: 파일 시스템 경로 접근
- `file_picker`: 파일 선택 기능
- `permission_handler`: 안드로이드 권한 관리
- `path`: 경로 처리 유틸리티

### 데이터 처리

- `dart:convert`: JSON 파싱 및 UTF-8 인코딩

## 앱 사용법

### 1. 초기 설정

1. 앱 설치 후 실행
2. 저장소 접근 권한 승인
3. 우측 상단 설정 버튼으로 Obsidian 볼트 경로 설정

### 2. 서비스 시작

1. 메인 화면에서 "서비스 시작" 버튼 클릭
2. 백그라운드에서 자동으로 파일 감지 시작
3. `/storage/emulated/0/Recordings/Summaries/` 폴더 모니터링

### 3. 자동 처리 과정

1. **파일 감지**: 새로운 JSON 파일 발견
2. **중복 확인**: 이미 처리된 파일인지 확인
3. **JSON 파싱**: 삼성 통화 요약 구조 분석
4. **마크다운 변환**: Obsidian 호환 형식으로 변환
5. **파일 저장**: 설정된 Obsidian 볼트에 저장
6. **기록 관리**: 처리 완료 기록을 데이터베이스에 저장

### 4. 파일 관리

- **"감지된 파일 보기"**: 변환된 마크다운 파일 목록 확인
- **설정 화면**: 처리 통계 및 기록 관리
- **테스트 기능**: 개발용 샘플 데이터 생성

## 모니터링 대상

앱은 다음 경로의 삼성 통화 요약 파일을 모니터링합니다:

```
/storage/emulated/0/Recordings/Summaries/
```

지원하는 파일 형식:

- `.json` 파일 (삼성 통화 요약 형식)
- 자동으로 `.md` 파일로 변환되어 Obsidian 볼트에 저장

## 권한

앱은 다음 안드로이드 권한이 필요합니다:

- `MANAGE_EXTERNAL_STORAGE`: 모든 파일 접근 (통화 요약 파일 읽기)
- `FOREGROUND_SERVICE`: 백그라운드 서비스 실행 (지속적인 파일 감지)
- `RECEIVE_BOOT_COMPLETED`: 부팅 시 서비스 자동 시작

## 개발 단계

### Phase 1: 프로젝트 초기 설정 및 권한 확보 ✅

- Flutter 프로젝트 생성 및 구조 설계
- 필수 라이브러리 추가 (총 8개 패키지)
- 안드로이드 권한 설정 및 매니페스트 구성
- 기본 권한 요청 UI 및 상태 관리

### Phase 2: 핵심 기능 - 파일 시스템 감지 ✅

- 백그라운드 파일 감지 서비스 구현
- 포그라운드 서비스로 안정적인 모니터링
- 10초마다 지정 디렉토리 스캔
- 새로운 JSON 파일 감지 및 실시간 알림
- 서비스 제어 UI (시작/중지/상태 확인)
- 감지된 파일 목록 표시 및 관리

### Phase 3: JSON 파싱 및 마크다운 변환 ✅

- 삼성 통화 요약 JSON 파싱 엔진 구현
- Obsidian 호환 마크다운 변환기 개발
- 자동 YAML Frontmatter 생성 (메타데이터 포함)
- 통화 상대방, 날짜, 키워드 자동 추출
- 세 줄 요약 및 전체 대화 내용 변환
- 마크다운 파일 관리 시스템 구축
- 개발용 테스트 데이터 생성 도구

### Phase 4: 중복 파일 감지 및 관리 ✅

- SQLite 기반 처리 기록 데이터베이스 구축
- 중복 파일 감지 및 자동 스킵 기능
- Obsidian 볼트 연동 및 자동 파일 생성
- 설정 관리 시스템 (경로 설정, 연결 테스트)
- 처리 통계 및 기록 관리 UI
- 완전한 end-to-end 워크플로우 구현

## 기술적 세부사항

### 아키텍처

- **백그라운드 서비스**: `flutter_background_service`를 사용한 지속적인 파일 모니터링
- **데이터베이스**: SQLite를 통한 처리 기록 관리 및 중복 방지
- **설정 관리**: SharedPreferences를 통한 사용자 설정 저장
- **파일 처리**: 비동기 처리를 통한 성능 최적화

### 지원 플랫폼

- **Android**: API 21+ (Android 5.0 이상)
- **권장**: Android 11+ (API 30+, MANAGE_EXTERNAL_STORAGE 권한 지원)

### 성능 특징

- **메모리 효율적**: 스트림 기반 파일 처리
- **배터리 최적화**: 효율적인 백그라운드 서비스 관리
- **확장 가능**: 모듈형 구조로 새로운 파일 형식 추가 용이

## 문제 해결

### 권한 관련 문제

- Android 11 이상에서 "모든 파일 접근" 권한 필요
- 설정 → 앱 → MemoriaTrace → 권한에서 수동 설정 가능

### 파일 감지 문제

- 모니터링 경로 확인: `/storage/emulated/0/Recordings/Summaries/`
- 서비스 재시작으로 해결 가능
- 로그 확인을 통한 디버깅

### Obsidian 연동 문제

- 설정에서 올바른 볼트 경로 설정 확인
- "연결 테스트" 기능으로 경로 유효성 검증
- 볼트 내 "Call Records" 폴더 자동 생성

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
