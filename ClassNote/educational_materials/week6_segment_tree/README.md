# 6주차 — Segment Tree

안녕하세요! 이번 주에는 **세그먼트 트리(Segment Tree)** 를 배웁니다. 세그먼트 트리는 "구간에 대한 질의와 업데이트를 빠르게 처리하는" 자료구조입니다. 예를 들어 "배열의 3번째부터 7번째 원소의 합은 얼마야?", "5번째 원소를 10으로 바꿔줘. 그리고 다시 합 알려줘." 같은 작업을 아주 빠르게 할 수 있습니다.

단순히 배열로 이런 일을 처리하려면 매번 O(N) 시간이 걸립니다. 원소가 10만 개이고 질의가 10만 번이라면 10^10 번 연산 — 이건 너무 느려요. 세그먼트 트리를 쓰면 업데이트도 O(log N), 쿼리도 O(log N)으로 줄어들어 같은 상황에서 10^5 × 17 ≈ 1,700,000 번 연산으로 끝납니다.

이번 주 목표: 합 세그트리 → 최댓값/최솟값 세그트리 → (보너스) Lazy Propagation 순서로 하나씩 쌓아 올립니다. 재귀 구현을 일관되게 사용하므로 코드 구조를 한 번 익히면 나머지는 "merge 함수만 교체"하면 됩니다.

---

## 목차

1. [세그먼트 트리란?](#1-세그먼트-트리란)
2. [합 세그먼트 트리](#2-합-세그먼트-트리)
3. [최댓값 / 최솟값 세그먼트 트리](#3-최댓값--최솟값-세그먼트-트리)
4. [(보너스) Lazy Propagation](#4-보너스-lazy-propagation)
5. [이번 주 핵심 정리](#이번-주-핵심-정리)

---

## 1. 세그먼트 트리란?

> **30초 요약**: 배열을 이진 트리 형태로 미리 전처리해 두면, 구간 합/최대/최소 쿼리와 점 업데이트를 모두 O(log N)에 처리할 수 있다.

### 왜 단순 배열로는 느린가?

배열 `a = [3, 1, 4, 1, 5, 9, 2, 6]` 이 있다고 하자.

| 작업 | 단순 배열 | 세그먼트 트리 |
|------|-----------|--------------|
| 구간 합 쿼리 (l, r) | O(N) — 매번 루프 | O(log N) |
| 점 업데이트 a[i] = v | O(1) | O(log N) |
| 구간 업데이트 (lazy) | O(N) | O(log N) |

Q: 업데이트가 O(1)이니까 단순 배열이 더 낫지 않나?
A: 쿼리가 M번이면 총 O(N·M). N = M = 100,000이면 10^10 — 제한 시간 초과입니다.

### 배열 vs 세그트리 — 구간 합 비교 그림

```
배열: [3, 1, 4, 1, 5, 9, 2, 6]
쿼리 sum(2..6) → 4+1+5+9+2 = 21  (인덱스 2~6, 매번 5번 덧셈)

세그트리:
            [0..7] = 31
           /            \
      [0..3]=9        [4..7]=22
      /     \          /     \
  [0..1]=4 [2..3]=5 [4..5]=14 [6..7]=8
  /  \     /  \     /  \      /  \
[0]=3[1]=1[2]=4[3]=1[4]=5[5]=9 [6]=2[7]=6

쿼리 sum(2..6):
  - [2..3]=5 (완전히 포함)
  - [4..5]=14 (완전히 포함)
  - [6]=2 (완전히 포함)
  → 5 + 14 + 2 = 21
  (단 3번의 노드 방문으로 완료!)
```

### 트리 크기는 왜 4N인가?

세그트리에서 진짜 신경 써야 할 것은 **사용되는 최대 노드 인덱스**다 (1-indexed로 자식이 `2*node, 2*node+1`이므로). 다음 식을 보자:

- M = N 이상인 가장 작은 2의 거듭제곱이라 하자. 정의상 `M < 2N` (N=2^k+1 같은 최악 케이스에서 M = 2·2^k < 2N).
- 1-indexed 세그트리에서 가능한 최대 인덱스는 `2M - 1` (높이 log₂M인 완전 이진 트리의 마지막 리프 인덱스).
- 따라서 가능한 최대 인덱스 < `2 · 2N = 4N`.

→ `tree[4 * N]`이면 어떤 N에 대해서도 인덱스 범위 내. (정확한 상한은 `2 · ceil_pow2(N)`이지만, 코딩 편의를 위해 4N을 잘 쓴다.)

```
N=5 예시:
  실제 리프 5개 → 필요한 2의 거듭제곱 = 8
  내부 노드 7개 + 리프 8개 = 15 < 4×5 = 20 ✓

N=8 (딱 2의 거듭제곱):
  내부 노드 7개 + 리프 8개 = 15 < 4×8 = 32 ✓
```

코드에서는 항상 `long long tree[4 * MAXN]` 으로 선언합니다.

---

## 2. 합 세그먼트 트리

> **30초 요약**: 트리의 각 노드에 "담당 구간의 합"을 저장한다. build로 초기화, update로 한 칸 수정, query로 구간 합을 구한다. 셋 다 O(log N).

### 일상 비유

학교 반 성적표를 생각해 보세요. 담임 선생님은 반 전체 평균, 조별 부장은 조원 합계, 개인은 본인 점수만 알고 있습니다. 누군가의 점수가 바뀌면 그 사람 → 조부장 → 담임 순으로 위로 올라가며 합계를 갱신합니다. 전체를 다시 다 더할 필요가 없죠. 세그트리가 정확히 이 구조입니다.

### 시각화

배열 `a = [3, 1, 4, 1, 5]` (0-indexed, N=5)

```
노드 번호 (1-based 트리 배열):

                  node 1
               [0..4] = 14
              /            \
         node 2              node 3
       [0..2] = 8          [3..4] = 6
       /      \             /      \
    node 4   node 5     node 6   node 7
   [0..1]=4  [2..2]=4  [3..3]=1  [4..4]=5
   /    \
node 8  node 9
[0]=3   [1]=1

각 노드의 의미:
  node[i] = tree[i] = 해당 구간에 속하는 원소들의 합
  왼쪽 자식: node[2*i],  오른쪽 자식: node[2*i+1]
  부모:      node[i/2]
```

```
인덱스 범위 매핑 (mid = (l+r)/2):
  node  1 : [0, 4]
  node  2 : [0, 2]   node  3 : [3, 4]
  node  4 : [0, 1]   node  5 : [2, 2]   node  6 : [3, 3]   node  7 : [4, 4]
  node  8 : [0, 0]   node  9 : [1, 1]
```

### 동작 원리 — 단계별

**Build (초기화)**
1. 리프 노드(단일 원소)에 `a[i]` 값을 저장한다.
2. 부모 = 왼쪽 자식 + 오른쪽 자식. 아래에서 위로 채운다.
3. 재귀: `build(node, l, r)` — `l==r`이면 `tree[node]=a[l]`, 아니면 반으로 쪼개고 재귀 후 합친다.

**Point Update (점 업데이트)**
1. `a[i] = v` 로 바꾸고 싶다.
2. 리프까지 내려가서 `tree[node] = v`.
3. 재귀가 돌아오면서 각 부모를 두 자식의 합으로 갱신.
4. 방문 노드 수 = 트리 높이 = O(log N).

**Range Sum Query (구간 합 쿼리)**
1. 현재 노드의 담당 구간 `[l, r]`과 쿼리 구간 `[ql, qr]`을 비교.
2. **완전 포함** `[ql, qr] ⊇ [l, r]`: `tree[node]` 바로 반환.
3. **완전 벗어남** `[ql, qr] ∩ [l, r] = ∅`: 0 반환.
4. **일부 겹침**: 왼쪽·오른쪽 자식에 재귀 → 합산.

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

// 트리 크기를 4*N으로 잡는 이유: N이 2의 거듭제곱이 아닐 때
// 이진 트리의 빈 노드를 포함하면 최대 4N개 노드가 필요하기 때문.
const int MAXN = 100005;
long long tree[4 * MAXN]; // 세그트리 배열 (1-indexed, node 1이 루트)
int a[MAXN];              // 원본 배열 (0-indexed)
int n;                    // 배열 크기

// ── build ────────────────────────────────────────────────────────────────
// node: 현재 트리 노드 번호
// l, r: 이 노드가 담당하는 원본 배열의 구간 [l, r]
void build(int node, int l, int r) {
    if (l == r) {
        // 리프 노드: 원소 1개를 그대로 저장
        tree[node] = a[l];
        return;
    }
    int mid = (l + r) / 2;
    build(2 * node,     l,     mid); // 왼쪽 자식 재귀
    build(2 * node + 1, mid+1, r  ); // 오른쪽 자식 재귀
    // 두 자식이 완성된 후, 부모 = 왼쪽 합 + 오른쪽 합
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

// ── update ───────────────────────────────────────────────────────────────
// idx: 바꾸려는 원본 배열 인덱스 (0-indexed)
// val: 새 값
void update(int node, int l, int r, int idx, int val) {
    if (l == r) {
        // 목표 리프 도착 → 값 교체
        a[idx]    = val;
        tree[node] = val;
        return;
    }
    int mid = (l + r) / 2;
    if (idx <= mid)
        update(2 * node,     l,     mid, idx, val); // 왼쪽 서브트리
    else
        update(2 * node + 1, mid+1, r,   idx, val); // 오른쪽 서브트리
    // 재귀에서 돌아오면 부모 값을 다시 계산
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

// ── query ────────────────────────────────────────────────────────────────
// ql, qr: 합을 구하려는 쿼리 구간 [ql, qr]
long long query(int node, int l, int r, int ql, int qr) {
    if (qr < l || r < ql)
        return 0; // 완전히 벗어남 → 기여 없음
    if (ql <= l && r <= qr)
        return tree[node]; // 완전히 포함 → 바로 반환
    // 일부 겹침 → 반으로 나눠 재귀
    int mid = (l + r) / 2;
    long long left  = query(2 * node,     l,     mid, ql, qr);
    long long right = query(2 * node + 1, mid+1, r,   ql, qr);
    return left + right;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // ── 데모 데이터 ──────────────────────────────────────────────
    n = 8;
    int arr[] = {3, 1, 4, 1, 5, 9, 2, 6};
    for (int i = 0; i < n; i++) a[i] = arr[i];

    // 세그트리 빌드
    build(1, 0, n - 1);

    // 쿼리 1: sum(0..7) = 31
    cout << "sum(0..7) = " << query(1, 0, n-1, 0, 7) << "\n"; // 31

    // 쿼리 2: sum(2..5) = 4+1+5+9 = 19
    cout << "sum(2..5) = " << query(1, 0, n-1, 2, 5) << "\n"; // 19

    // 업데이트: a[3] = 10 (원래 1 → 10, 차이 +9)
    update(1, 0, n-1, 3, 10);
    cout << "a[3]을 10으로 업데이트 후\n";

    // 쿼리 3: sum(0..7) = 31 + 9 = 40
    cout << "sum(0..7) = " << query(1, 0, n-1, 0, 7) << "\n"; // 40

    // 쿼리 4: sum(2..5) = 4+10+5+9 = 28
    cout << "sum(2..5) = " << query(1, 0, n-1, 2, 5) << "\n"; // 28

    return 0;
}
```

**예상 출력:**
```
sum(0..7) = 31
sum(2..5) = 19
a[3]을 10으로 업데이트 후
sum(0..7) = 40
sum(2..5) = 28
```

### 시간/공간 복잡도

| 연산 | 시간 복잡도 | 이유 |
|------|------------|------|
| build | O(N) | 모든 노드를 한 번씩 방문 |
| update (점) | O(log N) | 루트→리프 경로만 갱신 |
| query (구간 합) | O(log N) | 매 레벨에서 최대 2개 노드만 분기 |
| 공간 | O(N) | tree 배열 4N |

### 자주 하는 실수

1. **트리 크기를 N으로 선언**: `tree[N]`으로 잡으면 4N까지 접근하다 런타임 에러(배열 오버플로우)가 납니다. 반드시 `tree[4 * MAXN]`.
2. **쿼리 경계 조건 실수**: `if (qr < l || r < ql)` 에서 `<`와 `<=`를 헷갈려 틀린 구간을 반환합니다. "완전히 벗어났을 때"는 범위 밖이므로 엄격한 `<`입니다.
3. **int 오버플로우**: N = 100,000이고 원소값이 10^9라면 합이 10^14까지 커집니다. `tree`와 반환 타입을 `long long`으로 선언하세요.
4. **build 없이 query**: `tree` 배열을 초기화(0)한 채로 쿼리하면 항상 0이 나옵니다. 반드시 `build(1, 0, n-1)` 먼저!

### 연습문제

1. **BOJ 2042 — 구간 합 구하기**: 점 업데이트 + 구간 합의 교과서 문제. 위 코드를 그대로 적용 가능.
2. **BOJ 11659 — 구간 합 구하기 4**: 업데이트 없이 쿼리만. 누적 합과 세그트리 성능 비교 체험.
3. (심화) **BOJ 10868 — 최솟값**: 다음 섹션 내용을 미리 연습해보자.

---

## 3. 최댓값 / 최솟값 세그먼트 트리

> **30초 요약**: 합 세그트리와 완전히 같은 구조다. `tree[node] = left + right` 를 `tree[node] = max(left, right)` 또는 `min(left, right)` 로만 바꾸면 된다.

### 일상 비유

학교 체육대회에서 각 조별로 가장 빠른(혹은 가장 느린) 달리기 기록을 뽑습니다. 조부장은 자기 조 최고 기록만 알고, 담임은 반 전체 최고 기록을 압니다. 누군가의 기록이 바뀌면 역시 위로 올라가며 "더 빠른 쪽"을 선택해 갱신합니다. merge 함수가 `+` → `max` 로 바뀐 것뿐이에요.

### 시각화

배열 `a = [3, 1, 4, 1, 5, 9, 2, 6]` (N=8), 최댓값 세그트리:

```
                  node 1
               [0..7] MAX=9
              /             \
       node 2                 node 3
    [0..3] MAX=4           [4..7] MAX=9
     /       \              /         \
  node 4   node 5       node 6      node 7
[0..1]=3  [2..3]=4   [4..5]=9    [6..7]=6
  / \       / \         / \         / \
[0] [1]  [2] [3]    [4] [5]     [6] [7]
 3   1    4   1      5   9       2   6
```

```
최댓값 merge: tree[node] = max(tree[2*node], tree[2*node+1])
최솟값 merge: tree[node] = min(tree[2*node], tree[2*node+1])
```

### 동작 원리 — 단계별

합 세그트리와 100% 동일한 흐름. 다른 점:
- **build/update 에서 merge**: `max()` 또는 `min()` 사용.
- **query에서 반환하는 "중립값"**: 합은 0이지만, 최댓값은 `-INF`, 최솟값은 `+INF` (구간 밖에서 결과에 영향을 주지 않아야 하므로).

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

const int MAXN = 100005;
const int NEG_INF = INT_MIN; // 최댓값 쿼리용 중립값
const int POS_INF = INT_MAX; // 최솟값 쿼리용 중립값

// ── 최댓값 세그트리 ───────────────────────────────────────────────────────
int maxTree[4 * MAXN]; // 각 노드: 담당 구간의 최댓값
// ── 최솟값 세그트리 ───────────────────────────────────────────────────────
int minTree[4 * MAXN]; // 각 노드: 담당 구간의 최솟값

int a[MAXN];
int n;

// ── 두 트리를 동시에 빌드 ─────────────────────────────────────────────────
void build(int node, int l, int r) {
    if (l == r) {
        maxTree[node] = a[l]; // 리프: 원소 자체가 최댓값이자 최솟값
        minTree[node] = a[l];
        return;
    }
    int mid = (l + r) / 2;
    build(2 * node,     l,     mid);
    build(2 * node + 1, mid+1, r  );
    // merge: 합 대신 max/min
    maxTree[node] = max(maxTree[2 * node], maxTree[2 * node + 1]);
    minTree[node] = min(minTree[2 * node], minTree[2 * node + 1]);
}

// ── 업데이트: a[idx] = val ────────────────────────────────────────────────
void update(int node, int l, int r, int idx, int val) {
    if (l == r) {
        a[idx]        = val;
        maxTree[node] = val;
        minTree[node] = val;
        return;
    }
    int mid = (l + r) / 2;
    if (idx <= mid)
        update(2 * node,     l,     mid, idx, val);
    else
        update(2 * node + 1, mid+1, r,   idx, val);
    // 돌아오면서 부모 갱신
    maxTree[node] = max(maxTree[2 * node], maxTree[2 * node + 1]);
    minTree[node] = min(minTree[2 * node], minTree[2 * node + 1]);
}

// ── 구간 최댓값 쿼리 ──────────────────────────────────────────────────────
// 구간 밖: NEG_INF 반환 → max() 연산에서 무시됨
int queryMax(int node, int l, int r, int ql, int qr) {
    if (qr < l || r < ql) return NEG_INF;  // 완전 벗어남
    if (ql <= l && r <= qr) return maxTree[node]; // 완전 포함
    int mid = (l + r) / 2;
    int left  = queryMax(2 * node,     l,     mid, ql, qr);
    int right = queryMax(2 * node + 1, mid+1, r,   ql, qr);
    return max(left, right);
}

// ── 구간 최솟값 쿼리 ──────────────────────────────────────────────────────
// 구간 밖: POS_INF 반환 → min() 연산에서 무시됨
int queryMin(int node, int l, int r, int ql, int qr) {
    if (qr < l || r < ql) return POS_INF;  // 완전 벗어남
    if (ql <= l && r <= qr) return minTree[node]; // 완전 포함
    int mid = (l + r) / 2;
    int left  = queryMin(2 * node,     l,     mid, ql, qr);
    int right = queryMin(2 * node + 1, mid+1, r,   ql, qr);
    return min(left, right);
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    n = 8;
    int arr[] = {3, 1, 4, 1, 5, 9, 2, 6};
    for (int i = 0; i < n; i++) a[i] = arr[i];

    build(1, 0, n - 1);

    // 전체 구간 최댓값/최솟값
    cout << "max(0..7) = " << queryMax(1, 0, n-1, 0, 7) << "\n"; // 9
    cout << "min(0..7) = " << queryMin(1, 0, n-1, 0, 7) << "\n"; // 1

    // 구간 [2..5]: 원소 4,1,5,9
    cout << "max(2..5) = " << queryMax(1, 0, n-1, 2, 5) << "\n"; // 9
    cout << "min(2..5) = " << queryMin(1, 0, n-1, 2, 5) << "\n"; // 1

    // a[3] = 0 으로 업데이트 (원래 1 → 0)
    update(1, 0, n-1, 3, 0);
    cout << "a[3]=0 업데이트 후\n";

    // 구간 [2..5]: 원소 4,0,5,9
    cout << "max(2..5) = " << queryMax(1, 0, n-1, 2, 5) << "\n"; // 9
    cout << "min(2..5) = " << queryMin(1, 0, n-1, 2, 5) << "\n"; // 0

    // 전체 최솟값
    cout << "min(0..7) = " << queryMin(1, 0, n-1, 0, 7) << "\n"; // 0

    return 0;
}
```

**예상 출력:**
```
max(0..7) = 9
min(0..7) = 1
max(2..5) = 9
min(2..5) = 1
a[3]=0 업데이트 후
max(2..5) = 9
min(2..5) = 0
min(0..7) = 0
```

### 시간/공간 복잡도

합 세그트리와 동일합니다.

| 연산 | 시간 복잡도 |
|------|------------|
| build | O(N) |
| update (점) | O(log N) |
| queryMax / queryMin | O(log N) |
| 공간 | O(N) (tree 배열 4N) |

### 자주 하는 실수

1. **중립값을 0으로 쓰는 실수**: 최댓값 쿼리에서 구간 밖 노드를 0으로 반환하면, 모든 원소가 음수일 때 잘못된 답이 나옵니다. 반드시 `INT_MIN` / `INT_MAX` 를 사용하세요.
2. **합/최대 트리 혼용**: 프로젝트에서 두 종류를 함께 쓸 때 `maxTree`와 `sumTree`를 혼동해 잘못된 배열에 접근하는 실수가 잦습니다. 변수 이름을 명확히 구분하거나 구조체/클래스로 분리하세요.
3. **업데이트 후 merge 빠뜨리기**: `update` 함수에서 재귀 호출 뒤에 `maxTree[node] = max(...)` 라인을 빠뜨리면 부모 노드가 갱신되지 않습니다.

### 연습문제

1. **BOJ 2357 — 최솟값과 최댓값**: 구간 최솟값, 최댓값을 동시에 구하는 전형적인 문제. 위 코드 직접 적용 가능.
2. **BOJ 10868 — 최솟값**: 점 업데이트 없이 쿼리만 반복. 세그트리 최솟값의 가장 기본 형태.
3. (심화) **BOJ 17408 — 수열과 쿼리 24**: 최댓값 + 두 번째 최댓값을 동시에 트래킹하는 응용.

---

## 4. (보너스) Lazy Propagation

> **30초 요약**: 구간 전체를 한 번에 업데이트하고 싶을 때, 변경 사항을 "나중에" 자식에게 미루는 기법. 구간 업데이트 + 구간 쿼리 모두 O(log N).

### 일상 비유

대규모 온라인 쇼핑몰을 생각해 보세요. 마케팅팀이 "카테고리 A의 모든 상품 가격을 500원 인상해" 라고 요청합니다. 상품이 10만 개라면 지금 당장 10만 개 다 수정하는 건 너무 오래 걸립니다. 대신 카테고리 A 노드에 "나중에 +500 적용 예정" 이라는 스티커만 붙여 둡니다. 나중에 특정 상품을 실제로 조회하거나 더 세분화된 업데이트가 필요할 때, 그 스티커를 떼어 자식들에게 전달(propagate)합니다. 이것이 Lazy Propagation의 핵심입니다.

### 시각화

배열 `a = [1, 2, 3, 4, 5]` (N=5), 구간 [1..3]에 +10 lazy 업데이트:

```
업데이트 전:
           [0..4] sum=15
          /             \
     [0..2]=6          [3..4]=9
     /     \            /    \
  [0..1]=3 [2..2]=3  [3..3]=4 [4..4]=5
  /   \
[0]=1 [1]=2

구간 [1..3]에 +10 적용 (lazy 방식):

Step 1: node1 [0..4] — 일부 겹침, 자식으로 내려감
Step 2: node2 [0..2] — 일부 겹침, 자식으로 내려감
Step 3: node4 [0..1] — 일부 겹침, 자식으로 내려감
Step 4: node8 [0..0] — 벗어남, 패스
Step 5: node9 [1..1] — 완전 포함, lazy[9] += 10, sum 갱신(+10)
Step 6: node4 합 재계산
Step 7: node5 [2..2] — 완전 포함, lazy[5] += 10, sum 갱신(+10)
Step 8: node2 합 재계산
Step 9: node3 [3..4] — 일부 겹침, 자식으로 내려감
Step 10: node6 [3..3] — 완전 포함, lazy[6] += 10, sum 갱신(+10)
Step 11: node7 [4..4] — 벗어남, 패스
Step 12: node3 합 재계산

결과 트리 (lazy 값은 대괄호 안에):
           [0..4] sum=45
          /              \
     [0..2]=26           [3..4]=19
     /      \             /      \
  [0..1]=13  [2..2]=13  [3..3]=14 [4..4]=5
  /   \      (lazy:10)  (lazy:10)
[0]=1 [1]=12
      (lazy:10이 설정되지만, node9는 리프라 자식이 없어 lazy가 사용되지 않음. tree[9]는 update 시점에 이미 +10이 반영된 상태)
```

```
push_down(node):
  lazy[자식_왼] += lazy[node]
  lazy[자식_오] += lazy[node]
  tree[자식_왼] += lazy[node] * 자식_왼_구간_길이
  tree[자식_오] += lazy[node] * 자식_오_구간_길이
  lazy[node] = 0   ← 스티커 제거
```

### 동작 원리 — 단계별

**추가 배열 `lazy[]`**: 각 노드에 "아직 자식에게 전달하지 않은 누적 덧셈값"을 기록.

**업데이트 `rangeAdd(ql, qr, val)`**:
1. 현재 노드 구간이 완전 포함 → `tree[node] += val * (r-l+1)`, `lazy[node] += val`. 멈춤.
2. 완전 벗어남 → 무시.
3. 일부 겹침 → 먼저 `push_down`으로 lazy를 자식에게 전달, 그 다음 자식 재귀, 돌아와서 `tree[node]` 재계산.

**쿼리 `rangeQuery(ql, qr)`**:
1. 완전 포함 → `tree[node]` 반환.
2. 완전 벗어남 → 0 반환.
3. 일부 겹침 → 먼저 `push_down` (정확한 자식 값이 필요하므로), 그 다음 자식 재귀, 합산.

**push_down**: lazy 값을 두 자식에게 전달하고 `lazy[node]`를 0으로 리셋.

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

const int MAXN = 100005;
long long tree[4 * MAXN]; // 각 노드: 담당 구간의 합
long long lazy[4 * MAXN]; // 각 노드: 아직 자식에게 전달 안 한 누적 덧셈값

int a[MAXN];
int n;

// ── build ────────────────────────────────────────────────────────────────
void build(int node, int l, int r) {
    lazy[node] = 0; // 초기 lazy는 0 (미전달 덧셈 없음)
    if (l == r) {
        tree[node] = a[l];
        return;
    }
    int mid = (l + r) / 2;
    build(2 * node,     l,     mid);
    build(2 * node + 1, mid+1, r  );
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

// ── push_down ─────────────────────────────────────────────────────────────
// 현재 노드의 lazy를 두 자식에게 전달하고, lazy[node]를 초기화.
// l, r: 현재 노드의 담당 구간 (자식 구간 길이 계산에 필요)
void pushDown(int node, int l, int r) {
    if (lazy[node] == 0) return; // 전달할 것이 없으면 바로 리턴
    int mid = (l + r) / 2;
    // 왼쪽 자식: 구간 길이 = mid - l + 1
    tree[2 * node]     += lazy[node] * (mid - l + 1);
    lazy[2 * node]     += lazy[node];
    // 오른쪽 자식: 구간 길이 = r - mid
    tree[2 * node + 1] += lazy[node] * (r - mid);
    lazy[2 * node + 1] += lazy[node];
    // 현재 노드의 lazy 초기화 (전달 완료)
    lazy[node] = 0;
}

// ── rangeAdd: 구간 [ql, qr] 전체에 val을 더함 ────────────────────────────
void rangeAdd(int node, int l, int r, int ql, int qr, long long val) {
    if (qr < l || r < ql) return; // 완전 벗어남
    if (ql <= l && r <= qr) {
        // 완전 포함: 이 노드가 커버하는 원소 수만큼 합에 더하고, lazy에 기록
        tree[node] += val * (r - l + 1);
        lazy[node] += val;
        return;
    }
    // 일부 겹침: 먼저 현재 lazy를 자식에게 내려준 뒤 자식 재귀
    pushDown(node, l, r);
    int mid = (l + r) / 2;
    rangeAdd(2 * node,     l,     mid, ql, qr, val);
    rangeAdd(2 * node + 1, mid+1, r,   ql, qr, val);
    // 자식이 갱신됐으니 부모도 재계산
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

// ── rangeQuery: 구간 [ql, qr]의 합을 반환 ────────────────────────────────
long long rangeQuery(int node, int l, int r, int ql, int qr) {
    if (qr < l || r < ql) return 0; // 완전 벗어남
    if (ql <= l && r <= qr) return tree[node]; // 완전 포함
    // 일부 겹침: lazy를 내린 뒤 자식 탐색 (정확한 자식 값이 필요함)
    pushDown(node, l, r);
    int mid = (l + r) / 2;
    long long left  = rangeQuery(2 * node,     l,     mid, ql, qr);
    long long right = rangeQuery(2 * node + 1, mid+1, r,   ql, qr);
    return left + right;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    n = 5;
    int arr[] = {1, 2, 3, 4, 5};
    for (int i = 0; i < n; i++) a[i] = arr[i];

    build(1, 0, n - 1);

    // 초기 전체 합
    cout << "초기 sum(0..4) = " << rangeQuery(1, 0, n-1, 0, 4) << "\n"; // 15

    // 구간 [1..3]에 +10
    rangeAdd(1, 0, n-1, 1, 3, 10);
    cout << "[1..3] 전체 +10 후\n";
    cout << "sum(0..4) = " << rangeQuery(1, 0, n-1, 0, 4) << "\n"; // 15+30=45
    cout << "sum(1..3) = " << rangeQuery(1, 0, n-1, 1, 3) << "\n"; // 2+3+4+10*3=39

    // 구간 [0..4]에 +1
    rangeAdd(1, 0, n-1, 0, 4, 1);
    cout << "[0..4] 전체 +1 후\n";
    cout << "sum(0..4) = " << rangeQuery(1, 0, n-1, 0, 4) << "\n"; // 45+5=50
    cout << "sum(2..4) = " << rangeQuery(1, 0, n-1, 2, 4) << "\n"; // (3+10+1)+(4+10+1)+(5+1)=35

    return 0;
}
```

**예상 출력:**
```
초기 sum(0..4) = 15
[1..3] 전체 +10 후
sum(0..4) = 45
sum(1..3) = 39
[0..4] 전체 +1 후
sum(0..4) = 50
sum(2..4) = 35
```

### 시간/공간 복잡도

| 연산 | 시간 복잡도 | 이유 |
|------|------------|------|
| build | O(N) | 모든 노드 초기화 |
| rangeAdd (구간 업데이트) | O(log N) | lazy 덕분에 완전 포함 구간에서 멈춤 |
| rangeQuery (구간 합) | O(log N) | push_down 포함 |
| 공간 | O(N) | tree + lazy 배열 각 4N |

### 자주 하는 실수

1. **push_down 없이 자식 재귀**: 일부 겹침 구간을 처리할 때 push_down을 빠뜨리면 자식의 tree 값이 아직 lazy를 반영하지 않아 틀린 합이 나옵니다. 항상 자식으로 내려가기 전에 push_down을 호출하세요.
2. **`tree[node] += val * (r - l + 1)` 에서 구간 길이 계산 실수**: `(r - l + 1)` 대신 `(r - l)`을 쓰면 원소 개수가 1개 적게 더해집니다. off-by-one 오류입니다.
3. **lazy를 long long으로 선언 안 함**: 구간 업데이트 값이 크거나 여러 번 누적되면 int 오버플로우가 발생합니다. `long long lazy[]` 로 선언하세요.

### 연습문제

1. **BOJ 10277 — JuQueen**: 구간 업데이트(구간 덧셈) + 점 쿼리. Lazy Propagation의 가장 단순한 형태.
2. **BOJ 2268 — 수들의 합**: 점 업데이트 + 구간 합. 세그트리 기본형으로도 풀 수 있지만 lazy 버전으로 연습해 보기.
3. (심화) **BOJ 10999 — 구간 합 구하기 2**: 구간 업데이트 + 구간 합의 교과서 문제. 이 섹션 코드를 그대로 제출 가능.

---

## 이번 주 핵심 정리

```
┌─────────────────────────────────────────────────────────────────┐
│                    세그먼트 트리 치트시트                          │
├──────────────┬───────────────────────────────────────────────────┤
│ 트리 크기    │ long long tree[4 * MAXN]  (항상 4배!)             │
│ 루트        │ node = 1, 구간 = [0, n-1]                          │
│ 자식        │ 왼쪽 = 2*node, 오른쪽 = 2*node+1                   │
├──────────────┼───────────────────────────────────────────────────┤
│              │ 합    → +, 중립값 = 0                             │
│ merge 함수   │ 최대 → max(), 중립값 = INT_MIN                    │
│              │ 최소 → min(), 중립값 = INT_MAX                    │
├──────────────┼───────────────────────────────────────────────────┤
│              │ build:  O(N)                                       │
│ 복잡도       │ update: O(log N)                                   │
│              │ query:  O(log N)                                   │
├──────────────┼───────────────────────────────────────────────────┤
│              │ 구간 완전 포함 → tree[node] 바로 반환             │
│ 쿼리 3단계   │ 구간 완전 벗어남 → 중립값 반환                    │
│              │ 일부 겹침 → 자식 재귀 후 merge                    │
├──────────────┼───────────────────────────────────────────────────┤
│ Lazy 추가    │ lazy[4*MAXN] 배열 추가                             │
│ 규칙         │ 완전 포함 → tree 갱신 + lazy 기록                  │
│              │ 일부 겹침 → push_down 먼저, 그 다음 자식 재귀     │
├──────────────┼───────────────────────────────────────────────────┤
│ 흔한 실수    │ tree 크기 N (→ 4N), int 오버플로우 (→ long long)  │
│              │ 중립값 0 (→ 연산에 맞는 중립값), push_down 누락   │
└──────────────┴───────────────────────────────────────────────────┘
```

### 다음 주 예고

7주차에는 **차분 배열(Difference Array)**, **덱(Deque)**, **LCA(Lowest Common Ancestor)** 를 다룹니다. 특히 LCA는 이번 주에 배운 세그트리(Sparse Table / 세그트리로 구현 가능)와 연결되니 이번 주 내용을 잘 익혀두세요!
