#!/usr/bin/env python3
"""voc-raw.js -> voc-db.csv 변환. 매 확정 사이클 후 실행해 커밋하면
구글 드라이브 시트(IMPORTDATA 참조)가 자동으로 최신화된다."""
import json, re, csv, sys

CAT_NAMES = {
 'c1': '카테고리 1 인수/대여 프로세스 불편', 'c2': '카테고리 2 반납 사진/절차 단순화',
 'c3': '카테고리 3 매너평가 플로우/사용자 평가 시스템', 'c4': '카테고리 4 주유불량 페널티 정책 개선',
 'c5': '카테고리 5 스마트키 개선 및 위젯 추가', 'c6': '카테고리 6 차량 사용 관련 가이드 부족',
 'c7': '카테고리 7 CS 응대/고객센터 채널 부족', 'c8': '카테고리 8 차량 내 매너/애완동물 동반',
 'c9': '카테고리 9 반납 만차/외부차량/위치 식별', 'c10': '카테고리 10 특수 반납 안내',
}

src = open('voc-raw.js', encoding='utf-8').read()
data = json.loads(re.search(r'window\.VOC_RAW = (\{.*\});', src, re.S).group(1))

with open('voc-db.csv', 'w', encoding='utf-8', newline='') as f:
    w = csv.writer(f)
    # 사용후기 아카이브 — 점수 컬럼은 담지 않는다 (월/일/카테고리/사용후기만)
    w.writerow(['월', '일', '카테고리', '사용후기'])
    n = 0
    for ck in ['c1','c2','c3','c4','c5','c6','c7','c8','c9','c10']:
        for r in data['byCat'].get(ck, []):
            w.writerow([r['ym'], r['d'], CAT_NAMES[ck], r['t']])
            n += 1
print(f'voc-db.csv: {n} rows (meta.total={data["meta"]["total"]})', file=sys.stderr)
assert n == data['meta']['total'], 'row count != meta.total'
