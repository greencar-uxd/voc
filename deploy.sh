#!/bin/sh
# ============================================================
# G car VOC 대시보드 — GitHub Pages 배포 스크립트
# 최초 배포와 이후 갱신 모두 이 스크립트 하나로 처리한다.
#   사용법: ./deploy.sh [저장소명]   (기본: voc-dashboard)
#   선행 조건: gh CLI 로그인 (gh auth login --web)
# ============================================================
set -e
cd "$(dirname "$0")"

REPO_NAME="${1:-voc-dashboard}"

# gh CLI 탐색 (PATH → ~/.local/bin 순)
if command -v gh >/dev/null 2>&1; then GH="gh"
elif [ -x "$HOME/.local/bin/gh" ]; then GH="$HOME/.local/bin/gh"
else
  echo "✗ gh CLI를 찾을 수 없습니다. https://cli.github.com 에서 설치 후 재실행하세요."
  exit 1
fi

if ! "$GH" auth status >/dev/null 2>&1; then
  echo "✗ GitHub 로그인이 필요합니다. 먼저 실행:  $GH auth login --web"
  exit 1
fi

LOGIN="$("$GH" api user --jq .login)"
USER_ID="$("$GH" api user --jq .id)"

# push 전 식별 정보 자가 점검 (README 절대 규칙)
echo "→ data.js 식별 정보 점검 (집계 수치만 허용)…"
if grep -nE "[0-9]{2,3}[가-힣][[:space:]]?[0-9]{4}" data.js; then
  echo "✗ 차량번호로 보이는 패턴이 data.js에 있습니다. 제거 후 재실행하세요."
  exit 1
fi

# git 사용자 설정 (저장소 로컬, 미설정 시에만 GitHub 계정 기준으로)
git config user.name  >/dev/null 2>&1 || git config user.name "$LOGIN"
git config user.email >/dev/null 2>&1 || git config user.email "${USER_ID}+${LOGIN}@users.noreply.github.com"

# 커밋 (변경이 있을 때만)
git add -A
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git commit -m "G car VOC 대시보드 초기 배포 (데이터 버전 2026-06-10)"
elif ! git diff --cached --quiet; then
  git commit -m "data.js 갱신 $(date +%Y-%m-%d)"
else
  echo "→ 새 변경 없음 (커밋 생략)"
fi

# 원격 저장소 연결/생성
if ! git remote get-url origin >/dev/null 2>&1; then
  if "$GH" repo view "$LOGIN/$REPO_NAME" >/dev/null 2>&1; then
    git remote add origin "https://github.com/$LOGIN/$REPO_NAME.git"
  else
    echo "→ public 저장소 생성: $LOGIN/$REPO_NAME"
    echo "  (무료 계정의 GitHub Pages는 public 저장소에서만 동작)"
    "$GH" repo create "$REPO_NAME" --public --source=. --remote=origin
  fi
fi

git push -u origin main

# GitHub Pages 활성화 — Branch: main, 폴더: / (root). 이미 켜져 있으면 통과.
"$GH" api -X POST "repos/$LOGIN/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  && echo "→ GitHub Pages 활성화 완료 (main / root)" \
  || echo "→ GitHub Pages 이미 활성화됨"

echo ""
echo "✓ 공유용 링크: https://$LOGIN.github.io/$REPO_NAME/"
echo "  (반영까지 1~2분 소요. 갱신도 push 후 1~2분 내 자동 반영)"
