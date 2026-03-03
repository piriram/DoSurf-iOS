# SSH Share 인수인계 메모 (Option B)

작성 시각: 2026-03-01 02:42 (Asia/Seoul)

## 목적
M2 ↔ M2 간 파일 의뢰/결과물 공유를 `rsync + ssh` 수동 동기화 방식으로 운영.

## 확정값
- Remote: `ram@100.72.222.21:22`
- Local Sync Root: `/Users/piri/shared/ssh-bridge`
- Remote Sync Root: `/Users/ram/ssh-bridge`

## 폴더 구조 (양쪽 동일)
- `requests/` : 의뢰/요청
- `deliveries/` : 결과물
- `shared/` : 공용 자료
- `archive/` : 완료/보관
- `.sync-backups/` : rsync 백업(원격)

## 현재 상태
- SSH 키 기반 접속 설정 완료 (`~/.ssh/id_ed25519_m2_share`)
- 원격 `/Users/ram/ssh-bridge` 폴더 생성 및 권한 설정 완료
- 로컬 `/Users/piri/shared/ssh-bridge` 폴더 생성 완료
- `sync-pull.sh --dry-run`, `sync-push.sh --dry-run` 검증 완료

## 운영 문서 위치
- 로컬 문서 루트: `/Users/piri/shared/docs/ssh-share/`
  - `setup-checklist.md`
  - `sync-rules.md`
  - `handoff-to-remote-openclaw.md`
  - `sync-push.sh`, `sync-pull.sh`, `sync.env`

## 원격 전달 문서 위치
- `/Users/ram/Desktop/SSH-Share/`
  - `인수인계-ssh-share.md`
  - `setup-checklist.md`
  - `sync-rules.md`

## 기본 실행
```bash
cd /Users/piri/shared/docs/ssh-share
./sync-pull.sh
./sync-push.sh
```

## 주의
- 실행 전 가능하면 `--dry-run` 먼저
- 동시 수정 피하고, 기본 순서 `pull → 작업 → push`
- known_hosts/키 권한 유지 (`StrictHostKeyChecking=yes`)
