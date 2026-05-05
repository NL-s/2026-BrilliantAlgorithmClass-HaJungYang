# 7주차 — 차분 배열, Monotonic Deque, LCA

이번 주에는 세 가지 "영리한 트릭" 기법을 배운다. 이 기법들의 공통점은 하나다: **반복 작업을 미리 정리해 두면, 나중에 O(1)이나 O(log N)으로 답을 꺼낼 수 있다**는 것이다. 매번 처음부터 계산하는 대신, 이미 만들어 둔 구조를 재활용한다.

차분 배열은 "구간 전체에 같은 값을 더하는" 작업을 수천 번 반복해야 할 때 마법처럼 동작한다. 단조 덱은 슬라이딩 윈도우 안에서 매번 최댓값을 찾는 O(N·K) 방법 대신, 덱 하나로 O(N) 전체를 해결한다. LCA는 거대한 트리에서 두 노드의 "가장 가까운 공통 조상"을 O(log N)에 찾아내는데, 이를 위해 미리 "2의 거듭제곱 단위 점프" 테이블을 빌드한다.

세 기법 모두 처음에는 "왜 이렇게 복잡하게 저장하지?"라는 생각이 들 수 있다. 하지만 쿼리(질문)가 수십만 번 날아올 때, 미리 준비해 둔 구조가 얼마나 강력한지 실감하게 될 것이다.

---

## 1. 차분 배열 (Difference Array)

> **30초 요약**
> 구간 `[l, r]`에 `+k`를 더하는 작업을 O(1)로 처리한다. `diff[l] += k`, `diff[r+1] -= k`만 기록해 두고, 마지막에 누적합 한 번으로 실제 배열을 복원한다.

---

### 일상 비유

학교 조례 시간에 선생님이 "1번~3번 학생, 모두 의자를 한 칸 앞으로 당겨라"라고 한다. 학생이 1000명이라면 매번 1번부터 3번까지 찾아다니는 대신, **"1번에서 시작, 3번 다음에서 끝"이라는 표시만 칠판에 적어 두고** 나중에 한 번에 처리하는 것과 같다.

---

### 시각화

```
초기 배열(값 0):  [0, 0, 0, 0, 0, 0]   인덱스 1~6

업데이트 적용 (차분 배열 diff에만 기록):
  [1,3]+5  →  diff[1]+=5, diff[4]-=5
  [2,4]+3  →  diff[2]+=3, diff[5]-=3
  [3,6]+2  →  diff[3]+=2, diff[7]-=2

diff 배열:
  인덱스:   1    2    3    4    5    6    7
  값:      +5   +3   +2   -5   -3    0   -2

누적합 계산 (→ 실제 배열 복원):
  i=1: running = 0+5 = 5   → result[1] = 5
  i=2: running = 5+3 = 8   → result[2] = 8
  i=3: running = 8+2 = 10  → result[3] = 10
  i=4: running = 10-5 = 5  → result[4] = 5
  i=5: running = 5-3 = 2   → result[5] = 2
  i=6: running = 2+0 = 2   → result[6] = 2

최종 배열: [5, 8, 10, 5, 2, 2]
```

---

### 동작 원리 — 단계별

**왜 `diff[l] += k`, `diff[r+1] -= k`인가?**

누적합을 계산할 때 `i=l`부터 `+k`가 더해지기 시작하고, `i=r+1`에서 `-k`로 상쇄된다.
즉, 누적합을 취하면 정확히 `l`번째부터 `r`번째까지만 `k`가 더해진 효과가 난다.

**단계 1 — 차분 배열 초기화**
크기 `N+2`인 배열 `diff`를 0으로 초기화한다. (`r+1`이 `N+1`이 될 수 있으므로 여유 1칸 필요)

**단계 2 — 업데이트 기록 (각 O(1))**
구간 `[l, r]`에 `+k`:
```
diff[l]   += k;
diff[r+1] -= k;
```

**단계 3 — 누적합으로 복원 (O(N))**
```
running = 0;
for i in 1..N:
    running += diff[i];
    result[i] = running;
```

**전체 복잡도**: 업데이트 Q번 → O(Q) + 복원 O(N). 매번 구간을 순회하면 O(Q·N)이었을 것을 O(Q+N)으로 줄인다.

**2D 차분 배열 (짧은 언급)**
2차원 배열에서 직사각형 구간 `[r1,c1]~[r2,c2]`에 `+k`를 더하는 경우:
```
diff[r1][c1]     += k;
diff[r1][c2+1]   -= k;
diff[r2+1][c1]   -= k;
diff[r2+1][c2+1] += k;
```
이후 2D 누적합으로 복원한다. 원리는 1D와 동일하다.

---

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    // 원본 배열 크기 N = 6 (인덱스 1~6 사용)
    int N = 6;

    // diff[i] = "i 위치에서 변화량"을 기록하는 차분 배열
    // diff[l] += k, diff[r+1] -= k 를 하면
    // 나중에 누적합으로 [l, r] 전체에 +k 효과를 얻을 수 있다.
    vector<long long> diff(N + 2, 0);

    // 업데이트 1: [1, 3]에 +5
    // diff[1] += 5, diff[4] -= 5
    int l1 = 1, r1 = 3, k1 = 5;
    diff[l1] += k1;
    diff[r1 + 1] -= k1;

    // 업데이트 2: [2, 4]에 +3
    // diff[2] += 3, diff[5] -= 3
    int l2 = 2, r2 = 4, k2 = 3;
    diff[l2] += k2;
    diff[r2 + 1] -= k2;

    // 업데이트 3: [3, 6]에 +2
    // diff[3] += 2, diff[7] -= 2
    int l3 = 3, r3 = 6, k3 = 2;
    diff[l3] += k3;
    diff[r3 + 1] -= k3;

    // 차분 배열 누적합 → 실제 배열 복원
    // result[i] = diff[1] + diff[2] + ... + diff[i]
    vector<long long> result(N + 1, 0);
    long long running = 0;
    for (int i = 1; i <= N; i++) {
        running += diff[i];
        result[i] = running;
    }

    // 결과 출력
    cout << "인덱스: ";
    for (int i = 1; i <= N; i++) cout << i << " ";
    cout << "\n";

    cout << "결과값: ";
    for (int i = 1; i <= N; i++) cout << result[i] << " ";
    cout << "\n";

    // 기댓값: 인덱스 1=5, 2=8, 3=10, 4=5, 5=2, 6=2
    // [1,3]+5  -> 5 5 5 0 0 0
    // [2,4]+3  -> 5 8 8 3 0 0
    // [3,6]+2  -> 5 8 10 5 2 2
    cout << "기댓값: 5 8 10 5 2 2\n";

    return 0;
}
```

**출력:**
```
인덱스: 1 2 3 4 5 6
결과값: 5 8 10 5 2 2
기댓값: 5 8 10 5 2 2
```

---

### 시간/공간 복잡도

| 연산 | 복잡도 |
|------|--------|
| 구간 업데이트 1회 | O(1) |
| Q번 업데이트 전체 | O(Q) |
| 배열 복원 (누적합) | O(N) |
| 전체 | O(N + Q) |
| 공간 | O(N) |

기존 방법(구간마다 직접 순회)은 O(N·Q)였다. N=10^5, Q=10^5이면 10^10 연산 → TLE 확정. 차분 배열은 2×10^5 연산으로 끝낸다.

---

### 자주 하는 실수

1. **`diff[r+1]` 범위 초과**: `r`이 `N`일 때 `diff[N+1]`에 접근하므로 배열 크기를 `N+2`로 잡아야 한다. `N+1`로만 잡으면 런타임 에러(out-of-bounds).

2. **누적합 이전에 결과를 읽음**: 차분 배열은 업데이트 후 바로 값을 읽을 수 없다. 반드시 누적합 단계를 거친 뒤에 `result[i]`를 사용해야 한다. "업데이트 → 즉시 읽기"를 반복하는 패턴에는 차분 배열이 적합하지 않다.

3. **0-indexed vs 1-indexed 혼용**: 문제에서 인덱스가 0-based이면 `diff[r+1]`이 N이 될 수 있어 마찬가지로 크기를 1 더 확보해야 한다. 일관성 있게 선택할 것.

---

### 연습문제

1. **BOJ 11659 구간 합 구하기 4** — 차분 배열의 누적합 응용. 구간 합을 빠르게 처리하는 기초 문제.
2. **BOJ 10999 구간 합 구하기 2** — 구간에 값을 더하고 구간 합을 쿼리하는 문제. 차분 배열과 누적합을 함께 적용해야 한다.
3. **BOJ 2167 2차원 배열의 합** — 2D 누적합 연습. 2D 차분 배열로 확장하는 발판.

---

## 2. 단조 덱 (Monotonic Deque) — 슬라이딩 윈도우 최댓값

> **30초 요약**
> 길이 K짜리 윈도우가 배열을 지나가면서 매 위치의 최댓값을 구하는 문제를 O(N)에 해결한다. 덱(양방향 큐) 안을 항상 "앞쪽이 크고 뒤쪽이 작은" 단조 감소 상태로 유지한다.

---

### 일상 비유

콘서트장 맨 앞 K석이 "VIP 구역"이다. 새 관객이 줄 끝에서 들어올 때, 자기보다 키가 작은 앞 사람들을 전부 내보낸다(어차피 자기가 더 잘 보이므로 앞 사람은 최댓값 후보에서 탈락). VIP 구역 맨 앞 사람이 항상 그 시점 최장신, 즉 최댓값이다. 윈도우를 벗어난 가장 오래된 사람은 앞문으로 내보낸다.

---

### 시각화

```
배열 A: [3, 1, 2, 5, 4, 6, 2, 3],  K = 3
표기법: A[back]=X vs A[i]=Y → pop/keep (항상 "back값 vs 현재값" 순서)

i=0, A[0]=3: 덱=[]     → push(0)                          덱=[0]      (A값: [3])
i=1, A[1]=1: 덱=[0]    → A[back]=3 vs A[1]=1: 3>1 → keep; push(1)
                                                            덱=[0,1]   (A값: [3,1])
i=2, A[2]=2: 덱=[0,1]  → A[back]=1 vs A[2]=2: 1≤2 → pop(1)
             덱=[0]     → A[back]=3 vs A[2]=2: 3>2 → keep; push(2)
                                                            덱=[0,2]   (A값: [3,2])
             윈도우[0..2] 완성 → 최댓값 = A[dq.front()] = A[0] = 3  ✓

i=3, A[3]=5: 덱=[0,2]  → A[back]=2 vs A[3]=5: 2≤5 → pop(2)
             덱=[0]     → A[back]=3 vs A[3]=5: 3≤5 → pop(0); push(3)
             (0번 인덱스는 윈도우[1..3] 밖이라 이미 제거됨)
                                                            덱=[3]     (A값: [5])
             최댓값 = A[3] = 5  ✓

i=4, A[4]=4: 덱=[3]    → A[back]=5 vs A[4]=4: 5>4 → keep; push(4)
                                                            덱=[3,4]   (A값: [5,4])
             최댓값 = A[3] = 5  ✓

i=5, A[5]=6: 덱=[3,4]  → A[back]=4 vs A[5]=6: 4≤6 → pop(4)
             덱=[3]     → A[back]=5 vs A[5]=6: 5≤6 → pop(3); push(5)
                                                            덱=[5]     (A값: [6])
             최댓값 = A[5] = 6  ✓

i=6, A[6]=2: 덱=[5]    → A[back]=6 vs A[6]=2: 6>2 → keep; push(6)
                                                            덱=[5,6]   (A값: [6,2])
             최댓값 = A[5] = 6  ✓

i=7, A[7]=3: 덱=[5,6]  → A[back]=2 vs A[7]=3: 2≤3 → pop(6)
             덱=[5]     → A[back]=6 vs A[7]=3: 6>3 → keep; push(7)
                                                            덱=[5,7]   (A값: [6,3])
             최댓값 = A[5] = 6  ✓

결과: 3 5 5 6 6 6
```

---

### 동작 원리 — 단계별

**핵심 불변식**: 덱 안의 인덱스들은 앞→뒤 순서로 `A` 값이 단조 감소(non-increasing)를 유지한다.
→ 덱의 `front`는 항상 현재 윈도우에서 가장 큰 값의 인덱스.

**단계 1 — 뒤에서 pop (작은 값 제거)**
새 원소 `A[i]`를 넣기 전, 덱 뒤에서 `A[dq.back()] <= A[i]`인 동안 pop.
_왜?_ `dq.back()`은 `A[i]`보다 작고, 인덱스도 더 앞이다. 미래 어떤 윈도우에서도 `A[i]`가 살아있는 한 `dq.back()`이 최댓값이 될 수 없으므로 제거해도 안전하다.

**단계 2 — 뒤에서 push**
`dq.push_back(i)`.

**단계 3 — 앞에서 pop (범위 벗어남)**
`dq.front() <= i - K`이면 윈도우를 벗어났으므로 `dq.pop_front()`.

**단계 4 — 최댓값 읽기**
`i >= K-1`이면 `A[dq.front()]`가 답.

**왜 O(N)?** 각 원소는 덱에 최대 한 번 push, 한 번 pop된다. 전체 push+pop 횟수 ≤ 2N.

---

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    // 입력 배열과 윈도우 크기
    vector<int> A = {3, 1, 2, 5, 4, 6, 2, 3};
    int N = (int)A.size();
    int K = 3; // 윈도우 크기

    // 단조 감소 덱(deque):
    // 덱에는 "인덱스"를 저장한다. 앞쪽(front)이 현재 윈도우의 최댓값 인덱스.
    // 핵심 불변식: 덱 안의 인덱스들은 A값이 항상 앞->뒤로 감소(non-increasing).
    deque<int> dq; // 인덱스를 저장

    cout << "배열: ";
    for (int x : A) cout << x << " ";
    cout << "\n";
    cout << "K = " << K << "\n\n";

    cout << "윈도우 최댓값: ";

    for (int i = 0; i < N; i++) {
        // 1) 덱 뒤쪽: 현재 원소 A[i]보다 작거나 같은 값은 제거.
        //    왜? 어차피 현재 원소가 더 크고, 더 오래 남아 있으므로
        //    뒤에 있는 작은 값은 절대 최댓값이 될 수 없다.
        while (!dq.empty() && A[dq.back()] <= A[i]) {
            dq.pop_back();
        }
        dq.push_back(i);

        // 2) 덱 앞쪽: 윈도우를 벗어난 인덱스(i - K 이하) 제거.
        while (dq.front() <= i - K) {
            dq.pop_front();
        }

        // 3) 윈도우가 완성된 시점(i >= K-1)부터 최댓값 출력.
        if (i >= K - 1) {
            cout << A[dq.front()];
            if (i < N - 1) cout << " ";
        }
    }
    cout << "\n";

    // 기댓값:
    // [3,1,2]=3, [1,2,5]=5, [2,5,4]=5, [5,4,6]=6, [4,6,2]=6, [6,2,3]=6
    cout << "기댓값: 3 5 5 6 6 6\n";

    return 0;
}
```

**출력:**
```
배열: 3 1 2 5 4 6 2 3
K = 3

윈도우 최댓값: 3 5 5 6 6 6
기댓값: 3 5 5 6 6 6
```

---

### 시간/공간 복잡도

| 연산 | 복잡도 |
|------|--------|
| 전체 슬라이딩 윈도우 | O(N) |
| 각 원소 push/pop | 최대 1회씩 |
| 덱 공간 | O(K) |

단순 방법(매 윈도우마다 max 탐색)은 O(N·K). N=K=10^5이면 10^10 → 불가. 단조 덱은 O(N).

---

### 자주 하는 실수

1. **값이 아닌 인덱스를 덱에 저장해야 함**: 덱에 `A[i]` 값을 넣으면 윈도우 범위 체크(`dq.front() <= i - K`)를 할 수 없다. 반드시 인덱스를 저장하고, 값이 필요할 때 `A[dq.front()]`로 접근한다.

2. **pop 조건에서 `<` vs `<=` 혼동**: `A[dq.back()] < A[i]`(strictly less)로 쓰면 같은 값이 중복으로 남는다. 최댓값 문제에서는 `<=`로 pop해도 결과가 같지만, 최솟값 윈도우나 중복 처리가 중요한 문제에서 틀릴 수 있다. 문제 조건을 확인하자.

3. **최솟값 윈도우에서 방향 반대로**: 최솟값 슬라이딩 윈도우는 단조 증가 덱이 필요하다. "뒤에서 pop 조건"을 `A[dq.back()] >= A[i]`로 바꾸면 된다. 최댓값 코드를 그대로 쓰는 실수가 많다.

4. **front-pop 루프에 `!dq.empty()` 가드 잊지 말기**: 본 코드는 매 반복마다 `push_back(i)`를 먼저 하므로 front-pop 루프 진입 전 덱이 비어 있을 수 없다(보장). 하지만 일반적인 단조 덱 변형(예: 여러 테스트케이스 사이에 덱 재사용, 조건부 push)에서는 `while (!dq.empty() && dq.front() <= i - K)`처럼 빈 검사 가드를 명시해야 한다. 가드를 빠뜨리고 빈 덱에 `front()`를 부르면 segfault.

---

### 연습문제

1. **BOJ 11003 최솟값 찾기** — 슬라이딩 윈도우 최솟값. 단조 증가 덱으로 풀 수 있다. 단조 덱의 핵심 연습 문제.
2. **BOJ 1021 회전하는 큐** — 덱 자체의 조작을 다루는 문제. 덱 자료구조에 익숙해지는 데 좋다.
3. **BOJ 13422 도둑** — 원형 배열에서 슬라이딩 윈도우 최솟값. 단조 덱 + 원형 처리 응용.

---

## 3. LCA (Lowest Common Ancestor, 최소 공통 조상)

> **30초 요약**
> 트리에서 두 노드 u, v의 "가장 가까운 공통 조상"을 O(log N)에 찾는다. 미리 `parent[k][v]` (v의 2^k번째 조상) 테이블을 빌드해 두고, 깊이를 맞춘 뒤 같이 점프한다.

---

### 일상 비유

가족 족보를 생각해 보자. "나"와 "사촌"의 가장 가까운 공통 조상은 "할아버지"다. 족보가 수백 세대라면 한 단계씩 올라가면 너무 느리다. 미리 "2세대 위", "4세대 위", "8세대 위" 조상을 모든 사람에 대해 적어 두면, 임의의 두 사람의 공통 조상을 몇 번의 점프로 찾을 수 있다.

---

### 시각화

```
트리 구조 (노드 7개, 루트=1):

        1          depth 0
       / \
      2   3        depth 1
     / \   \
    4   5   6      depth 2
        |
        7          depth 3

parent[0] (직접 부모):
  parent[0][1]=1  parent[0][2]=1  parent[0][3]=1
  parent[0][4]=2  parent[0][5]=2  parent[0][6]=3
  parent[0][7]=5

parent[1] (2칸 위 조상 = 2^1):
  parent[1][7] = parent[0][parent[0][7]] = parent[0][5] = 2
  parent[1][4] = parent[0][parent[0][4]] = parent[0][2] = 1
  parent[1][6] = parent[0][parent[0][6]] = parent[0][3] = 1

parent[2] (4칸 위 조상 = 2^2):
  parent[2][7] = parent[1][parent[1][7]] = parent[1][2] = 1
  (루트 이상은 루트 자신)

LCA(4, 6) 쿼리:
  depth[4]=2, depth[6]=2  → 깊이 같음, diff=0
  같이 올리기:
    k=2: parent[2][4]=1, parent[2][6]=1  → 같으므로 올리지 않음
    k=1: parent[1][4]=1, parent[1][6]=1  → 같으므로 올리지 않음
    k=0: parent[0][4]=2, parent[0][6]=3  → 다르므로 4→2, 6→3
  → u=2, v=3, parent[0][2]=1
  LCA = 1  ✓

LCA(4, 5) 쿼리:
  depth[4]=2, depth[5]=2  → 깊이 같음
  k=0: parent[0][4]=2, parent[0][5]=2  → 같으므로 올리지 않음
  → u=4, v=5, parent[0][4]=2
  LCA = 2  ✓
```

---

### 동작 원리 — 단계별

**전처리: Sparse Table (Binary Lifting)**

`parent[k][v]` = "v에서 2^k번 위로 올라간 조상"

빌드 점화식:
```
parent[0][v] = v의 직접 부모  (BFS로 구함)
parent[k][v] = parent[k-1][ parent[k-1][v] ]
```
"2^k번 올라가기 = 2^(k-1)번 올라간 뒤 다시 2^(k-1)번 올라가기"

이렇게 LOG×N 크기의 테이블을 O(N log N)에 빌드한다.

**쿼리: LCA(u, v)**

_1단계 — 깊이 맞추기_
더 깊은 쪽을 위로 올려서 두 노드의 depth를 같게 만든다.
`diff = depth[u] - depth[v]`를 이진 분해해서 점프(아래는 의사코드):
```text
for k in 0..LOG-1:
    if (diff >> k) & 1:
        u = parent[k][u]
```

_2단계 — 같은 노드면 LCA_
`u == v`이면 그 노드가 LCA.

_3단계 — 같이 점프 (LCA 바로 아래까지)_
큰 k부터 내려오면서, `parent[k][u] != parent[k][v]`이면 둘 다 올린다.
(같아지면 올리지 않는다 — 이미 LCA를 지나쳤을 수 있으므로)
루프 후 `u`와 `v`는 LCA의 직접 자식에 위치.
→ `parent[0][u]`가 LCA.

**복잡도**: 전처리 O(N log N), 쿼리 O(log N).

---

### C++ 코드

```cpp
#include <bits/stdc++.h>
using namespace std;

// 노드 수 N, LOG = ceil(log2(N))
const int MAXN = 8;
const int LOG = 3; // ceil(log2(7)) = 3

int parent[LOG][MAXN]; // parent[k][v] = v의 2^k번째 조상
int depth[MAXN];
vector<int> adj[MAXN];

// BFS로 depth와 parent[0] (직접 부모) 초기화
void bfs(int root) {
    queue<int> q;
    q.push(root);
    depth[root] = 0;
    parent[0][root] = root; // 루트의 부모는 루트 자신으로 처리

    while (!q.empty()) {
        int v = q.front(); q.pop();
        for (int u : adj[v]) {
            if (depth[u] == -1) { // 아직 방문 안 한 노드
                depth[u] = depth[v] + 1;
                parent[0][u] = v; // 직접 부모
                q.push(u);
            }
        }
    }
}

// Sparse Table (Binary Lifting) 빌드
// parent[k][v] = parent[k-1][ parent[k-1][v] ]
// "2^k번 올라가기 = 2^(k-1)번 올라간 뒤 다시 2^(k-1)번 올라가기"
void buildSparseTable(int N) {
    for (int k = 1; k < LOG; k++) {
        for (int v = 1; v <= N; v++) {
            parent[k][v] = parent[k-1][ parent[k-1][v] ];
        }
    }
}

// LCA 쿼리: u, v의 최소 공통 조상 반환
int lca(int u, int v) {
    // 1단계: 깊이를 맞춘다 (더 깊은 쪽을 위로 올림)
    if (depth[u] < depth[v]) swap(u, v);
    int diff = depth[u] - depth[v];

    // diff만큼 u를 위로 올림 (이진 표현으로 점프)
    for (int k = 0; k < LOG; k++) {
        if ((diff >> k) & 1) {
            u = parent[k][u];
        }
    }

    // 2단계: 같은 노드면 그게 LCA
    if (u == v) return u;

    // 3단계: 같이 올라가되, LCA 바로 아래까지만 올라간다
    for (int k = LOG - 1; k >= 0; k--) {
        if (parent[k][u] != parent[k][v]) {
            u = parent[k][u];
            v = parent[k][v];
        }
    }
    // 지금 u, v는 LCA의 직접 자식
    return parent[0][u];
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    int N = 7;

    // 트리 구조 (1-indexed, 1이 루트):
    //        1
    //       /|
    //      2  3
    //    / |   |
    //   4  5   6
    //      |
    //      7
    adj[1].push_back(2); adj[2].push_back(1);
    adj[1].push_back(3); adj[3].push_back(1);
    adj[2].push_back(4); adj[4].push_back(2);
    adj[2].push_back(5); adj[5].push_back(2);
    adj[3].push_back(6); adj[6].push_back(3);
    adj[5].push_back(7); adj[7].push_back(5);

    // depth 초기화 (-1 = 미방문)
    fill(depth + 1, depth + N + 1, -1);

    bfs(1);
    buildSparseTable(N);

    // depth 출력
    cout << "노드별 깊이: ";
    for (int v = 1; v <= N; v++) cout << "node" << v << "=" << depth[v] << " ";
    cout << "\n\n";

    // LCA 쿼리
    vector<pair<int,int>> queries = {{4, 6}, {7, 6}, {4, 5}, {2, 7}};
    for (auto [u, v] : queries) {
        cout << "LCA(" << u << ", " << v << ") = " << lca(u, v) << "\n";
    }

    return 0;
}
```

**출력:**
```
노드별 깊이: node1=0 node2=1 node3=1 node4=2 node5=2 node6=2 node7=3

LCA(4, 6) = 1
LCA(7, 6) = 1
LCA(4, 5) = 2
LCA(2, 7) = 2
```

---

### 시간/공간 복잡도

| 연산 | 복잡도 |
|------|--------|
| 전처리 (BFS + Sparse Table) | O(N log N) |
| LCA 쿼리 1회 | O(log N) |
| Q번 쿼리 전체 | O((N + Q) log N) |
| 공간 (parent 테이블) | O(N log N) |

단순 방법(한 칸씩 올라가기)은 O(N) per query → Q번이면 O(N·Q). 트리 깊이가 N-1인 체인 모양에서 최악. Binary Lifting은 O(log N) per query로 줄인다.

---

### 자주 하는 실수

1. **루트의 `parent[0][root]`를 초기화 안 함**: 루트의 부모를 미정의 상태로 두면 깊이 맞추기 루프나 공통 조상 탐색 중 범위를 벗어난 인덱스에 접근한다. 루트는 `parent[k][root] = root`로 설정하는 것이 안전하다.

2. **LOG 값 잡기**: 정확한 공식은 `LOG = ceil(log2(N))`이지만, 실전에서는 N의 상한이 바뀔 수 있고 한 번 잡은 테이블을 여러 문제에 재사용하기 때문에 `LOG = 20` (`2^20 ≈ 10^6` 대응)처럼 충분히 크게 고정해 두는 것이 안전하다. 핵심은 `2^LOG > 트리의 최대 깊이`만 만족하면 됨.

3. **단계 3에서 조건 방향 혼동**: `parent[k][u] != parent[k][v]`일 때 올려야 한다(LCA가 아니라는 의미). `== `일 때 올리면 LCA를 이미 지나쳐서 잘못된 답이 나온다. "다를 때 올린다, 같을 때는 올리지 않는다"를 기억하자.

4. **depth 배열 초기화 누락**: BFS 전에 `depth`를 `-1`로 초기화해야 방문 여부를 구분할 수 있다. `0`으로 초기화하면 루트(depth=0)와 미방문 노드가 구분되지 않아 BFS가 잘못 동작한다.

---

### 연습문제

1. **BOJ 11437 LCA** — Binary Lifting 없이 O(N) BFS + O(N) per query로 풀 수 있는 기본 문제. LCA 개념을 확인한다.
2. **BOJ 11438 LCA 2** — 노드 수 10^5, 쿼리 10^5. Binary Lifting이 없으면 TLE. 이번 주 코드를 직접 적용하는 문제.
3. **BOJ 1761 정점들의 거리** — LCA를 이용해 두 노드 사이의 거리(간선 수)를 구하는 응용 문제. `dist(u,v) = depth[u] + depth[v] - 2*depth[LCA(u,v)]`.

---

## 이번 주 핵심 정리

### 차분 배열 (Difference Array)

| 항목 | 내용 |
|------|------|
| 용도 | 구간 `[l,r]`에 `+k` 업데이트를 O(1)로 처리 |
| 핵심 연산 | `diff[l] += k; diff[r+1] -= k;` |
| 복원 | 누적합 1회 O(N) |
| 전체 복잡도 | O(N + Q) |
| 주의 | 배열 크기 N+2, 누적합 후에 읽기 |

### 단조 덱 (Monotonic Deque)

| 항목 | 내용 |
|------|------|
| 용도 | 슬라이딩 윈도우 최댓값/최솟값 O(N) |
| 저장 내용 | 값이 아닌 **인덱스** |
| 불변식 | 덱 앞→뒤 값이 단조 감소(최댓값) 또는 단조 증가(최솟값) |
| pop 조건 (최댓값) | `A[dq.back()] <= A[i]`이면 back pop |
| 범위 체크 | `dq.front() <= i - K`이면 front pop |
| 전체 복잡도 | O(N) |

### LCA (Binary Lifting)

| 항목 | 내용 |
|------|------|
| 용도 | 트리에서 두 노드의 최소 공통 조상 |
| 전처리 | BFS + Sparse Table O(N log N) |
| 쿼리 | O(log N) |
| 테이블 | `parent[k][v]` = v의 2^k번째 조상 |
| 빌드 | `parent[k][v] = parent[k-1][parent[k-1][v]]` |
| 쿼리 절차 | ① 깊이 맞추기 ② 같으면 LCA 반환 ③ 다를 때 같이 올리기 |
| 주의 | 루트 자기자신 초기화, LOG 충분히 크게 |

---

> **세 기법의 공통 메시지**: 미리 O(N) 또는 O(N log N)을 투자해서 구조를 만들어 두면, 수십만 번의 쿼리를 O(1) 또는 O(log N)으로 답할 수 있다. "느린 정직한 방법 vs 영리한 전처리"의 차이가 시간 초과(TLE)와 통과를 가른다.
