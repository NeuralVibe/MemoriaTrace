# MemoriaTrace

MemoriaTrace는 안드로이드에서 파일 시스템을 모니터링하고 관리하는 Flutter 앱입니다.

## 기능

- 파일 시스템 접근 및 모니터링
- 백그라운드 서비스 실행
- 권한 관리
- 중복 파일 처리를 위한 데이터베이스

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
├── main.dart                 # 앱 진입점 및 권한 요청
├── services/                 # 백그라운드 서비스
├── models/                   # 데이터 모델
├── screens/                  # UI 화면
└── utils/                    # 유틸리티 함수
```

## 사용된 라이브러리

- `path_provider`: 파일 시스템 경로 접근
- `file_picker`: 파일 선택 기능
- `flutter_background_service`: 백그라운드 서비스
- `permission_handler`: 안드로이드 권한 관리
- `sqflite`: 로컬 데이터베이스

## 권한

앱은 다음 안드로이드 권한이 필요합니다:

- `MANAGE_EXTERNAL_STORAGE`: 모든 파일 접근
- `FOREGROUND_SERVICE`: 백그라운드 서비스 실행
- `RECEIVE_BOOT_COMPLETED`: 부팅 시 서비스 자동 시작

## 개발 단계

### Phase 1: 프로젝트 초기 설정 및 권한 확보 ✅

- Flutter 프로젝트 생성
- 필수 라이브러리 추가
- 안드로이드 권한 설정
- 기본 권한 요청 UI

### Phase 2: 핵심 기능 - 파일 시스템 감지 ✅

- 백그라운드 파일 감지 서비스 구현
- 포그라운드 서비스로 안정적인 모니터링
- 10초마다 지정 디렉토리 스캔
- 새로운 .txt 파일 감지 및 알림
- 서비스 제어 UI (시작/중지)
- 감지된 파일 목록 표시

### Phase 3: JSON 파싱 및 마크다운 변환 ✅

- 삼성 통화 요약 JSON 파싱 엔진
- 옵시디언(Obsidian)용 마크다운 변환기
- 자동 YAML Frontmatter 생성
- 통화 상대방, 날짜, 키워드 추출
- 세 줄 요약 및 전체 대화 내용 변환
- 마크다운 파일 관리 시스템
- 테스트 데이터 생성 도구

### Phase 4: 중복 파일 감지 및 관리 (예정)

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
