@echo off
echo MemoriaTrace 프로젝트 설정 및 실행 스크립트
echo ================================================

echo.
echo Phase 2 완료: 백그라운드 파일 감지 서비스 구현
echo - 포그라운드 서비스로 안정적인 파일 모니터링
echo - 10초마다 지정 디렉토리 스캔
echo - 새로운 .txt 파일 감지 및 알림 기능
echo.

echo 1. Flutter SDK 확인 중...
flutter --version
if %errorlevel% neq 0 (
    echo Flutter SDK가 설치되지 않았습니다. 
    echo Flutter 공식 웹사이트에서 설치해주세요: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo 2. 프로젝트 의존성 설치 중...
flutter pub get
if %errorlevel% neq 0 (
    echo 의존성 설치에 실패했습니다.
    pause
    exit /b 1
)

echo.
echo 3. 연결된 디바이스 확인 중...
flutter devices

echo.
echo 4. 프로젝트 빌드 및 실행
echo 주요 기능:
echo - 파일 시스템 접근 권한 요청
echo - 백그라운드 파일 감지 서비스
echo - 서비스 시작/중지 제어
echo - 감지된 파일 목록 보기
echo.
echo 계속하려면 아무 키나 누르세요...
pause

flutter run

echo.
echo 프로젝트 실행이 완료되었습니다.
pause
