# Google Play 한국어 메타데이터

Fastlane `supply`의 `metadata_path`를 `fastlane/metadata/android`로 지정할 때 쓰는
한국어(`ko-KR`) 디렉터리다. MAR-34에서 Marco가 문구를 확정한 뒤 아래 파일을
추가한다.

- `title.txt`
- `short_description.txt`
- `full_description.txt`

스토어용 스크린샷은 최종 검토 뒤 `images/phoneScreenshots`에 복사해 업로드할 수
있지만, 이 저장소의 자동화에는 업로드 lane이나 Google 서비스 계정 키가 없다.
