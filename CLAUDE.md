# 작업 지침

[출력 원칙]
- 결론부터. 서론·요약 반복·맺음말 인사 금지.
- 묻지 않은 내용 추가 설명 금지. 확장은 요청받을 때만.
- 만들기 전에 판단: 꼭 필요한가 → 이미 있는 걸 재사용 가능한가
  → 표준 기능으로 되는가 → 그래도 필요하면 최소한만.
- 예시는 1개면 충분. 같은 말 다르게 반복 금지.
- 검증·에러 처리·보안·접근성은 축약 대상에서 제외.

[검증 원칙]
- 팩트 / 추론 / 확인 필요를 구분해 표기.
- 외부 사실은 출처 명시. 근거 없으면 없다고 말할 것.
- 불확실하면 단정 대신 가능 시나리오로.

[진행 원칙]
- 매 단계 확인받지 말고 자율 진행. 막힐 때만 질문.

---

## 이 레포 고유 규칙

**무엇인가:** 그린카 만족도 설문의 사용후기 중 UX 개선·앱 안내로 사용성을 높일 수 있는 것만 10개 카테고리로 분류해 월별 추이를 보여주는 정적 대시보드. 빌드 스텝 없음.
`index.html`(로직) ← `data.js`(집계) + `voc-raw.js`(원문) + `lib/chart.umd.js`. 원문 아카이브는 `voc-db.csv`(공개 배포 → 구글 시트가 IMPORTDATA로 참조).

### 배포

- **PR → squash merge to `main` → GitHub Pages 자동 배포.** 라이브: https://greencar-uxd.github.io/voc/
- 원격 저장소명은 `voc` (로컬 디렉토리명 `voc-dashboard`와 다름). Pages URL도 `/voc/`
- 머지 후 "pages build and deployment" 워크플로우 성공까지 확인. 실패 시 rerun → 그래도 안 되면 무해한 커밋으로 새 run 트리거
- `deploy.sh`는 최초 배포용(gh CLI 필요). 평소 갱신에 쓰지 않는다

### 건드리지 말 것

- **고객번호는 어떤 파일에도 넣지 않는다.** 공개 저장소다. RAW 엑셀 추출 시 해당 컬럼을 버린다.
  단 **사용후기 원문·차량번호는 공개 대상** — 차량번호는 회사 소유 카셰어링 차량이라 개인 식별정보가 아니다(사용자 확정).
  `README.md`의 "VOC 원문 금지"는 **`data.js`에 한정**된 규칙이며 원문 아카이브 파일에는 적용되지 않는다.
- `data.js` — 집계 수치만. `months`·`cumulative`·`fullRegime`만 고치면 누적·비율·순위·라벨은 `index.html`이 자동 계산한다. 파생 수치를 손으로 넣지 말 것
- `voc-raw.js` — 원문 정본. 파이썬으로 `window.VOC_RAW = {...}` 정규식 파싱 → dict 수정 → `json.dumps(ensure_ascii=False, indent=1)` 재작성. 손편집 금지
- `voc-db.csv` — 생성 산출물. 직접 편집 금지, `python3 scripts/export_voc_db.py`로 재생성. 컬럼은 `날짜·카테고리·사용후기` 3개 고정(점수 컬럼 넣지 말 것)
- `lib/chart.umd.js` — 로컬 사본. CDN 링크로 바꾸지 말 것(오프라인 `file://` 동작 보장)
- `.nojekyll` — 삭제 금지. 없으면 Pages가 CSV를 그대로 서빙하지 않는다

### 수치 반영 전 검산 (필수)

```sh
node -e "
const vm=require('vm'),fs=require('fs');const ctx={window:{}};vm.createContext(ctx);
vm.runInContext(fs.readFileSync('data.js','utf8'),ctx);
vm.runInContext(fs.readFileSync('voc-raw.js','utf8'),ctx);
const d=ctx.window.VOC_DATA,r=ctx.window.VOC_RAW,f=d.months.filter(x=>x.regime==='full');
const m=d.months[d.months.length-1];
console.log(m.total===Object.values(m.categories).reduce((a,b)=>a+b,0),
 f.reduce((a,x)=>a+x.total,0)===d.cumulative.byRegime.full,
 d.fullRegime.days===f.reduce((a,x)=>a+x.days,0),
 d.cumulative.total===Object.values(d.cumulative.byCategory).reduce((a,b)=>a+b,0),
 d.cumulative.total===Object.values(d.cumulative.byRegime).reduce((a,b)=>a+b,0),
 r.meta.total===Object.values(r.byCat).reduce((a,v)=>a+v.length,0));"
```

전부 `true`가 아니면 반영하지 않는다.

### 분류 작업

- **역할:** Claude는 high-recall 분류기, 사용자가 precision 필터. **경계 건은 기본 IN으로 제안**하고 최종 컷은 사용자가 한다
- **대조 보고는 항상 풀텍스트.** 요약하지 말고 ①공통 IN ②놓침 ③내 강추인데 컷 ④판단 일치를 **원문 전문** 표로 낸다
- 룰셋 SSOT는 `rules/`. **반복 확인된 판단만** `classification-rules.md`에 승격하고, 단발 사례는 `decision-log.md`에 케이스별로 남긴다(최신이 위)
- 게이트(범위 밖): 청결 결과 · 정비/외관 · 요금/쿠폰 · 차종/공급 · 버그/시스템 오류 · 물리적 접근 제약 · 순수 칭찬
- 카테고리 표기는 **"카테고리 N + 정식 분류명" 완전 표기**. `c1`~`c10`은 코드 식별자로만 쓰고 화면·보고서에 노출하지 않는다
- 시간 축은 **월 단위만** — 일별·요일별·주차별 집계를 만들지 않는다

### 반복해서 틀렸던 것

- **주유·연료 소재를 "단문이라"·"부수 언급이라" 컷했다가 4회 연속 놓침** → 짧아도 살린다(룰셋 §5에 승격)
- 반납 절차 단문("반납과정 편리했으면")을 막연하다고 컷 → 대상이 불명확해도 간소화 취지면 IN
- 귀속은 **제안된 해법의 형식이 아니라 문제의 본질**로 판단한다("실내 사진 촬영 의무화" 제안이지만 본질이 매너 검증이면 카테고리 3)
- `git rebase origin/main`을 dirty tree에서 실행해 실패 → 커밋 먼저 하고 `git rebase --onto origin/main HEAD~1`
