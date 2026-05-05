# 2주차 — 분할 정복, 병합 정렬, 이분 탐색, 투 포인터

안녕하세요, 여러분! 2주차에 오신 것을 환영합니다.

이번 주는 코딩 테스트에서 가장 자주 등장하는 네 가지 핵심 기법을 배웁니다. **분할 정복**은 "큰 문제를 작게 쪼개서 푼다"는 사고방식의 뿌리가 됩니다. **병합 정렬**은 그 사고방식을 정렬 문제에 그대로 적용한 예시이고, **이분 탐색**은 "정렬된 상태"를 최대한 활용해 O(log n)으로 원하는 값을 찾아냅니다. **투 포인터**는 두 개의 인덱스를 똑똑하게 움직여 O(n²)짜리 완전탐색을 O(n)으로 줄이는 마법 같은 기법입니다.

네 기법 모두 **"정렬된 구조"** 또는 **"문제를 반으로 줄이는 성질"** 을 이용한다는 공통점이 있습니다. 이번 주를 마치면 여러분은 O(n log n) 이하 풀이를 자연스럽게 떠올릴 수 있게 됩니다. 화이팅!

```mermaid
flowchart TD
    A[큰 문제] --> B{분할 정복\n반으로 쪼개기}
    B --> C[병합 정렬\n쪼갠 뒤 합치면서 정렬]
    B --> D[이분 탐색\n쪼개서 절반 제거]
    C --> E[정렬된 배열]
    E --> F[투 포인터\n양 끝에서 좁혀오기]
    D --> G[O(log n) 탐색]
    F --> H[O(n) 탐색]
```

---

## 1. 분할 정복 (Divide and Conquer)

> **30초 요약**: 풀기 어려운 큰 문제를 같은 형태의 작은 문제 여러 개로 **나누고(Divide)**, 각 작은 문제를 **재귀적으로 해결(Conquer)** 한 뒤, 그 결과를 **합쳐(Combine)** 원래 문제의 답을 구하는 알고리즘 설계 패러다임입니다. 핵심은 "작은 문제가 원래 문제와 완전히 같은 구조"라는 점입니다.

### 일상 비유

전화번호부(1000페이지짜리 책)에서 "홍길동"을 찾는다고 상상해 보세요. 처음부터 한 장씩 넘기면 최악의 경우 1000번을 봐야 합니다. 그런데 **딱 가운데를 펼쳐** 이름이 앞쪽인지 뒤쪽인지 확인하면 절반을 단번에 버릴 수 있습니다. 이걸 계속 반복하면 10번도 안 돼서 찾을 수 있습니다. 이것이 바로 분할 정복의 핵심 아이디어입니다.

### 시각화 — 거듭제곱 a^n 계산

```
a^8 을 계산한다
              a^8
             /
           a^4 × a^4        ← 8을 반으로 (짝수)
           /
         a^2 × a^2          ← 4를 반으로 (짝수)
         /
       a^1 × a^1            ← 2를 반으로 (짝수)
       /
     a^1                    ← 기저: n=1이면 그냥 a 반환

총 곱셈 횟수: 3번  (log2(8) = 3)
단순 반복이었다면: 7번
```

홀수 예시: a^7

```
a^7 = a^3 × a^3 × a        ← 7은 홀수: 절반(3)을 재귀 + 남은 a 한 번 더 곱함
a^3 = a^1 × a^1 × a
a^1 → 기저
```

### 동작 원리 — 단계별

1. **기저 조건(Base Case) 확인**: n == 0이면 1 반환, n == 1이면 a 반환.
2. **Divide**: 지수 n을 2로 나눈다. `half = power(a, n/2)`를 재귀 호출.
3. **Conquer**: 재귀 호출이 반환될 때까지 기다린다.
4. **Combine**: n이 짝수이면 `half * half`, 홀수이면 `half * half * a`.
5. 재귀 깊이는 O(log n)이므로 총 곱셈 횟수도 O(log n).

### C++ 코드

```cpp
// g++ -std=c++17 -Wall -o /tmp/wk2_0.bin /tmp/wk2_0.cpp
#include <bits/stdc++.h>
using namespace std;

// ── 분할 정복으로 a^n mod m 계산 ──────────────────────────────────────────
// 경쟁 프로그래밍에서는 보통 mod를 함께 사용합니다 (결과가 매우 커지므로)
long long power(long long a, long long n, long long mod) {
    // 기저 조건: 지수가 0이면 1 (a^0 = 1)
    if (n == 0) return 1 % mod;

    // ① Divide: 지수를 절반으로 나눔
    long long half = power(a, n / 2, mod);

    // ② Combine: 절반의 결과를 제곱
    long long result = (half * half) % mod;

    // ③ 지수가 홀수이면 a를 한 번 더 곱함
    // 예: a^7 = (a^3)^2 * a
    if (n % 2 == 1) {
        result = (result * a) % mod;
    }
    return result;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    // 데모: 2^10 = 1024, 3^0 = 1, 5^3 = 125
    long long mod = 1e9 + 7; // 코테 단골 모듈러

    cout << "2^10 mod (1e9+7) = " << power(2, 10, mod) << "\n";  // 1024
    cout << "3^0  mod (1e9+7) = " << power(3, 0,  mod) << "\n";  // 1
    cout << "5^3  mod (1e9+7) = " << power(5, 3,  mod) << "\n";  // 125
    cout << "2^30 mod (1e9+7) = " << power(2, 30, mod) << "\n";  // 73741817 (2^30=1073741824, mod 1e9+7)

    // 재귀 호출 흐름 직접 확인 (mod 없는 단순 버전)
    // 2^8 = 256
    // power(2,8) → power(2,4) → power(2,2) → power(2,1) → 기저 반환 2
    // ← 2*2=4, ← 4*4=16, ← 16*16=256

    cout << "\n[분할 정복 호출 깊이 시뮬레이션 — 2^8]\n";
    // 지수 8: log2(8)=3 단계
    for (long long exp : {1LL, 2LL, 4LL, 8LL, 16LL, 32LL}) {
        cout << "2^" << exp << " = " << power(2, exp, (long long)1e18) << "\n";
    }

    return 0;
}
```

### 시간/공간 복잡도

| 항목 | 복잡도 | 이유 |
|------|--------|------|
| 시간 | O(log n) | 매 재귀마다 n이 절반으로 줄어듦 |
| 공간 | O(log n) | 재귀 호출 스택 깊이 |

단순 반복(`for`문으로 n번 곱하기)은 O(n)이므로, n = 10^18 같은 큰 값에서는 분할 정복만이 실용적입니다.

### 자주 하는 실수

1. **mod를 half를 만들 때 빼먹기**: `half * half`가 `long long` 범위(약 9.2 × 10^18)를 넘으면 오버플로우 발생. 반드시 `(half * half) % mod`처럼 매 곱셈마다 mod 적용.
2. **n == 0인 기저 조건 누락**: `power(a, 0, mod)`를 호출했는데 기저 처리가 없으면 무한 재귀 → 스택 오버플로우.
3. **홀짝 분기 착각**: `n % 2 == 1`일 때 `result * a`를 곱하는 것을 잊어버려 `a^6` 결과가 `a^7` 자리에 나옴.

### 연습문제

1. **BOJ 1629 — 곱셈**: a^b mod c 를 구하라. 이 코드를 그대로 적용할 수 있습니다.
2. **BOJ 10830 — 행렬 제곱**: 행렬의 거듭제곱. `power` 함수에서 `long long` 대신 2D 배열 구조체를 사용하면 됩니다.
3. **손풀이**: 3^13을 분할 정복으로 계산하면 곱셈을 몇 번 해야 할까요? (힌트: 13을 이진수로 표현해 보세요: 1101₂)

---

## 2. 병합 정렬 (Merge Sort)

> **30초 요약**: 배열을 절반으로 **나누고(Divide)**, 각 절반을 재귀적으로 **정렬(Conquer)** 한 뒤, 두 정렬된 절반을 하나로 **합치는(Merge)** 분할 정복 기반 정렬 알고리즘입니다. 항상 O(n log n)을 보장하며, 같은 값의 원소 순서를 유지하는 **안정 정렬(Stable Sort)** 이라는 특징이 있습니다.

### 일상 비유

도서관에서 두 사서가 각자 절반씩 카드를 알파벳 순으로 정렬했습니다. 이제 합쳐야 하는데, 두 더미 맨 위 카드를 **비교해서 작은 것을 가져가는** 작업을 반복하면 금방 하나로 합칠 수 있습니다. 병합 정렬은 이 직관을 재귀적으로 확장한 것입니다.

### 시각화

```
원본: [5, 3, 8, 1, 9, 2, 7, 4]

── Divide 단계 ──────────────────────────────
[5,3,8,1]          [9,2,7,4]
[5,3]   [8,1]      [9,2]   [7,4]
[5][3]  [8][1]     [9][2]  [7][4]

── Conquer + Merge 단계 (아래에서 위로) ──────
[3,5]   [1,8]      [2,9]   [4,7]
   [1,3,5,8]          [2,4,7,9]
         [1,2,3,4,5,7,8,9]
```

병합(Merge) 단계 상세 — `[3,5]`와 `[1,8]` 합치기:

```
왼쪽 포인터 i=0, 오른쪽 포인터 j=0, 결과 배열 tmp=[]

3 vs 1 → 1 선택 (j++)   tmp=[1]
3 vs 8 → 3 선택 (i++)   tmp=[1,3]
5 vs 8 → 5 선택 (i++)   tmp=[1,3,5]
왼쪽 소진 → 8 그대로    tmp=[1,3,5,8]
```

### 동작 원리 — 단계별

1. **Divide**: 배열의 중간 인덱스 `mid = (left + right) / 2`를 계산해 왼쪽 `[left..mid]`와 오른쪽 `[mid+1..right]`로 나눈다.
2. **Conquer**: `mergeSort(arr, left, mid)`와 `mergeSort(arr, mid+1, right)` 재귀 호출.
3. **기저 조건**: `left >= right`이면 원소가 1개 이하 → 이미 정렬됨, 바로 반환.
4. **Merge**: 임시 배열에 두 정렬된 절반을 작은 것부터 순서대로 복사.
5. 임시 배열 내용을 원본 배열로 덮어쓴다.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall -o /tmp/wk2_1.bin /tmp/wk2_1.cpp
#include <bits/stdc++.h>
using namespace std;

// 병합 함수: arr[left..mid]와 arr[mid+1..right]를 합침
void merge(vector<int>& arr, int left, int mid, int right) {
    // 임시 버퍼에 두 절반을 복사
    vector<int> tmp;
    tmp.reserve(right - left + 1); // 메모리 미리 확보

    int i = left;       // 왼쪽 절반 포인터
    int j = mid + 1;    // 오른쪽 절반 포인터

    // 두 절반에서 작은 값을 순서대로 tmp에 넣기
    while (i <= mid && j <= right) {
        if (arr[i] <= arr[j]) {
            // 안정 정렬: 같은 값이면 왼쪽(i)을 먼저 → 원래 순서 유지
            tmp.push_back(arr[i++]);
        } else {
            tmp.push_back(arr[j++]);
        }
    }

    // 왼쪽 절반에 남은 원소 처리
    while (i <= mid)    tmp.push_back(arr[i++]);
    // 오른쪽 절반에 남은 원소 처리
    while (j <= right)  tmp.push_back(arr[j++]);

    // 임시 버퍼를 원본 배열에 덮어쓰기
    for (int k = 0; k < (int)tmp.size(); k++) {
        arr[left + k] = tmp[k];
    }
}

// 병합 정렬 메인 함수
void mergeSort(vector<int>& arr, int left, int right) {
    // 기저 조건: 원소가 1개 이하이면 정렬 완료
    if (left >= right) return;

    int mid = left + (right - left) / 2; // 오버플로우 방지 표현식

    // Divide + Conquer: 왼쪽 절반 정렬
    mergeSort(arr, left, mid);
    // Divide + Conquer: 오른쪽 절반 정렬
    mergeSort(arr, mid + 1, right);
    // Combine: 두 정렬된 절반을 병합
    merge(arr, left, mid, right);
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    vector<int> arr = {5, 3, 8, 1, 9, 2, 7, 4};

    cout << "정렬 전: ";
    for (int x : arr) cout << x << " ";
    cout << "\n";

    mergeSort(arr, 0, (int)arr.size() - 1);

    cout << "정렬 후: ";
    for (int x : arr) cout << x << " ";
    cout << "\n";

    // 안정 정렬 확인: 같은 값의 순서가 유지되는지
    // pair<값, 원래인덱스>로 테스트
    vector<pair<int,int>> pairs = {{3,0},{1,1},{3,2},{2,3},{1,4}};
    // 값만 비교해 정렬 (안정 정렬이므로 같은 값은 원래 인덱스 순서 유지)
    stable_sort(pairs.begin(), pairs.end(),
        [](const pair<int,int>& a, const pair<int,int>& b){
            return a.first < b.first;
        });
    cout << "\n안정 정렬 결과 (값, 원래인덱스):\n";
    for (auto& p : pairs) cout << "(" << p.first << "," << p.second << ") ";
    cout << "\n";

    return 0;
}
```

### 시간/공간 복잡도

| 항목 | 복잡도 | 이유 |
|------|--------|------|
| 시간 (최선/평균/최악) | O(n log n) | 항상 절반으로 나눔: log n 단계 × 각 단계 O(n) 병합 |
| 공간 | O(n) | 병합용 임시 배열 필요 |
| 안정 정렬 여부 | 안정(Stable) | `arr[i] <= arr[j]` 조건에서 같을 때 왼쪽 우선 |

**퀵 정렬과 비교**: 퀵 정렬은 평균 O(n log n)이지만 최악 O(n²). 병합 정렬은 항상 O(n log n). 대신 추가 메모리 O(n) 필요.

### 자주 하는 실수

**왜 O(n log n)인가? (점화식 유도)**

병합 정렬은 입력을 절반으로 나눠 각각 재귀 호출하고, 합치는 데 O(n) 시간이 든다. 이를 점화식으로 쓰면:

- T(n) = 2 · T(n/2) + O(n), T(1) = O(1)

펼쳐 보면: T(n) = 2 T(n/2) + n = 4 T(n/4) + 2n = 8 T(n/8) + 3n = ... = n · T(1) + (log₂ n) · n = O(n log n).

마스터 정리(Master Theorem)로 검증해도 a=2, b=2, f(n)=Θ(n), log_b a = 1 → case 2이므로 Θ(n log n). 이 점화식 분석 패턴은 분할 정복 문제 전반에 그대로 적용된다.

1. **`mid` 계산 오버플로우**: `(left + right) / 2`에서 `left + right`가 `int` 최댓값을 초과할 수 있습니다. 반드시 `left + (right - left) / 2`를 사용하세요.
2. **병합 후 임시 배열을 원본에 복사 안 함**: `tmp`에 제대로 합쳤는데 `arr`에 쓰는 걸 빠뜨리면 정렬이 반영되지 않습니다.
3. **기저 조건을 `left > right`로만 설정**: `left == right`(원소 1개)도 종료해야 합니다. `left >= right`가 올바릅니다.

### 연습문제

1. **BOJ 2751 — 수 정렬하기 2**: N ≤ 1,000,000의 정수를 정렬. `std::sort`도 되지만 직접 구현 연습으로 좋습니다.
2. **BOJ 24060 — 알고리즘 수업 - 병합 정렬 1**: 병합 정렬 과정에서 k번째로 저장되는 수를 구하는 문제. 코드 흐름을 정확히 이해해야 풀 수 있습니다.
3. **BOJ 1517 — 버블 소트**: 병합 정렬 과정에서 역전 쌍(inversion) 개수를 세면 O(n log n)으로 풀립니다. 응용 문제입니다.

---

## 3. 이분 탐색 (Binary Search)

> **30초 요약**: **정렬된 배열**에서 목표 값을 찾을 때, 매번 탐색 범위를 절반으로 줄여 나가는 알고리즘입니다. 선형 탐색(O(n))과 달리 O(log n)만에 답을 찾을 수 있습니다. "정답 자체를 이분 탐색"하는 패턴으로 확장하면 최적화 문제에도 강력하게 쓸 수 있습니다.

> **단조성(monotonicity)이란?** 입력이 증가할 때 결과(또는 어떤 술어 predicate)가 같거나 항상 한 방향으로만 변하는 성질. 정렬된 배열은 "값이 인덱스에 대해 비감소"라는 단조성의 한 사례. "정답을 이분 탐색하는" 패턴이 통하는 이유는 술어 `check(x)`가 어떤 경계 x*를 기준으로 한 번만 false→true(또는 true→false)로 뒤집히기 때문이다. 이 단조성이 깨지면 이분 탐색은 잘못된 답을 낸다.

**왜 단조 술어에서 이분 탐색이 정확한가?** `check(x)`가 단조라면 `{x | check(x) = true}` 집합은 `[0, x*]` 또는 `[x*, ∞)` 같은 **연결된 구간** 형태다. 이 구간의 경계 x*를 찾는 작업은 정렬 배열에서 값 위치를 찾는 작업과 정확히 같은 구조라 이분 탐색이 그대로 적용된다.

### 일상 비유

1부터 100까지 숫자 중 상대방이 생각한 숫자를 맞히는 게임을 해본 적 있나요? "높아요/낮아요" 힌트를 받으면서, 항상 **현재 범위의 중간 숫자**를 부르면 최악의 경우 7번(log₂100 ≈ 7)만에 맞출 수 있습니다. 처음부터 1, 2, 3... 순서로 부르면 최악 100번이 걸리죠. 이것이 이분 탐색입니다.

### 시각화

배열: `[1, 3, 5, 7, 9, 11, 13, 15]`, 찾는 값: `7`

```
인덱스:  0   1   2   3   4    5    6    7
값:      1   3   5   7   9   11   13   15
        [lo              hi]
         ↑   ↑   ↑   ↑   ↑    ↑    ↑    ↑

단계 1: lo=0, hi=7, mid=3 → arr[3]=7 == target → 찾음!

만약 찾는 값이 11이었다면:
단계 1: lo=0, hi=7, mid=3 → arr[3]=7 < 11 → lo=mid+1=4
         [            lo          hi]
단계 2: lo=4, hi=7, mid=5 → arr[5]=11 == target → 찾음!
```

### lower_bound / upper_bound 다이어그램

```
배열: [1, 3, 3, 3, 5, 7]
인덱스: 0  1  2  3  4  5

lower_bound(3) → 인덱스 1  (3이 처음 나타나는 위치)
upper_bound(3) → 인덱스 4  (3보다 큰 첫 번째 위치)

         lower_bound(3)
              ↓
[1,  3,  3,  3,  5,  7]
      ↑           ↑
      1            4 ← upper_bound(3)

3의 개수 = upper_bound(3) - lower_bound(3) = 4 - 1 = 3
```

### 동작 원리 — 단계별

1. **초기화**: `lo = 0`, `hi = n - 1`.
2. **반복 조건**: `lo <= hi`인 동안 반복.
3. **중간 계산**: `mid = lo + (hi - lo) / 2`.
4. **비교 및 범위 조정**:
   - `arr[mid] == target` → 찾음, 반환.
   - `arr[mid] < target` → 목표가 오른쪽에 있음, `lo = mid + 1`.
   - `arr[mid] > target` → 목표가 왼쪽에 있음, `hi = mid - 1`.
5. **반복 종료 후 `lo > hi`** → 값이 없음, `-1` 반환.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall -o /tmp/wk2_2.bin /tmp/wk2_2.cpp
#include <bits/stdc++.h>
using namespace std;

// ── 1. 직접 구현한 이분 탐색 ─────────────────────────────────────────────
// 정렬된 배열 arr에서 target을 찾아 인덱스 반환, 없으면 -1
int binarySearch(const vector<int>& arr, int target) {
    int lo = 0;
    int hi = (int)arr.size() - 1;

    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2; // 오버플로우 방지

        if (arr[mid] == target) {
            return mid; // 찾음!
        } else if (arr[mid] < target) {
            lo = mid + 1; // 오른쪽 절반만 탐색
        } else {
            hi = mid - 1; // 왼쪽 절반만 탐색
        }
    }
    return -1; // 없음
}

// ── 2. 정답을 이분 탐색하는 패턴 ─────────────────────────────────────────
// 예제: "나무 자르기" 스타일
// 문제: N개의 나무가 있고 높이 배열이 주어진다.
//       톱 높이를 H로 설정하면 H보다 큰 나무는 (높이-H)만큼 잘린다.
//       잘린 나무 합이 M 이상이 되는 최대 H를 구하라.
//
// 핵심 아이디어: H가 커질수록 잘리는 양이 단조 감소 → 이분 탐색 가능!

// H로 자를 때 얼마나 얻는지 계산
long long getWood(const vector<int>& trees, long long H) {
    long long total = 0;
    for (int t : trees) {
        if (t > H) total += t - H; // H보다 큰 나무만 잘림
    }
    return total;
}

int cutTree(const vector<int>& trees, long long M) {
    long long lo = 0;
    long long hi = *max_element(trees.begin(), trees.end()); // 최대 높이

    long long answer = 0;
    while (lo <= hi) {
        long long mid = lo + (hi - lo) / 2;
        long long wood = getWood(trees, mid);

        if (wood >= M) {
            // mid 높이로 충분히 얻을 수 있음 → H를 더 높여볼 수 있다
            answer = mid; // 현재 mid가 유효한 답
            lo = mid + 1; // 더 큰 H 탐색 (최대값 구하므로)
        } else {
            // 잘리는 양이 부족 → H를 낮춰야 함
            hi = mid - 1;
        }
    }
    return (int)answer;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    // ── 기본 이분 탐색 테스트 ──────────────────────────────────────────────
    vector<int> arr = {1, 3, 5, 7, 9, 11, 13, 15};
    cout << "배열: ";
    for (int x : arr) cout << x << " ";
    cout << "\n";

    cout << "binarySearch(7)  = 인덱스 " << binarySearch(arr, 7)  << "\n"; // 3
    cout << "binarySearch(6)  = 인덱스 " << binarySearch(arr, 6)  << "\n"; // -1
    cout << "binarySearch(1)  = 인덱스 " << binarySearch(arr, 1)  << "\n"; // 0
    cout << "binarySearch(15) = 인덱스 " << binarySearch(arr, 15) << "\n"; // 7

    // ── STL lower_bound / upper_bound ──────────────────────────────────────
    cout << "\n=== STL lower_bound / upper_bound ===\n";
    vector<int> v = {1, 3, 3, 3, 5, 7};
    cout << "배열: ";
    for (int x : v) cout << x << " ";
    cout << "\n";

    // lower_bound: target 이상인 첫 번째 위치 (iterator 반환)
    auto lb = lower_bound(v.begin(), v.end(), 3);
    // upper_bound: target 초과인 첫 번째 위치
    auto ub = upper_bound(v.begin(), v.end(), 3);

    cout << "lower_bound(3) 인덱스: " << (lb - v.begin()) << "\n"; // 1
    cout << "upper_bound(3) 인덱스: " << (ub - v.begin()) << "\n"; // 4
    cout << "3의 개수: " << (ub - lb) << "\n"; // 3

    // 4가 없는 경우
    auto lb4 = lower_bound(v.begin(), v.end(), 4);
    cout << "lower_bound(4) 인덱스: " << (lb4 - v.begin()) // 4 (5의 위치)
         << " → 값: " << *lb4 << "\n";

    // ── 나무 자르기 패턴 ───────────────────────────────────────────────────
    cout << "\n=== 나무 자르기 (정답을 이분 탐색) ===\n";
    // 나무 높이: [20, 15, 10, 17], 필요한 목재량: 7
    vector<int> trees = {20, 15, 10, 17};
    long long M = 7;
    cout << "나무 높이: 20 15 10 17\n";
    cout << "필요한 목재량: " << M << "\n";
    cout << "최대 톱 높이: " << cutTree(trees, M) << "\n"; // 15

    return 0;
}
```

### 시간/공간 복잡도

| 항목 | 복잡도 | 이유 |
|------|--------|------|
| 이분 탐색 시간 | O(log n) | 매 반복마다 탐색 범위 절반 감소 |
| 이분 탐색 공간 | O(1) | 포인터 변수만 사용 |
| 나무 자르기 시간 | O(n log H) | H 범위에서 log H번 탐색 × 매번 O(n) 검증 |
| lower/upper_bound | O(log n) | STL 내부적으로 이분 탐색 사용 |

### 자주 하는 실수

1. **정렬 안 된 배열에 이분 탐색 적용**: 이분 탐색은 반드시 **정렬된 배열**에서만 동작합니다. `sort` 먼저!
2. **`lo < hi` vs `lo <= hi`**: `lo < hi`를 쓰면 원소가 1개 남았을 때 확인하지 않고 종료합니다. 기본 탐색은 `lo <= hi`, "정답 이분 탐색" 패턴은 목적에 따라 다름.
3. **`mid = (lo + hi) / 2` 오버플로우**: `lo + hi`가 int 최대를 초과할 수 있습니다. `lo + (hi - lo) / 2` 사용.
4. **"정답 이분 탐색"에서 단조성 확인 생략**: 이분 탐색이 적용되려면 check(x)가 true/false 경계가 단 한 곳이어야 합니다. 단조성 없는 문제에 쓰면 틀립니다.

### 연습문제

1. **BOJ 1920 — 수 찾기**: 정렬 후 이분 탐색 기본기. `lower_bound` 활용 연습.
2. **BOJ 2805 — 나무 자르기**: 바로 위 코드의 원본 문제입니다.
3. **BOJ 2110 — 공유기 설치**: "최솟값의 최댓값" 유형. 이분 탐색 + 그리디 검증 조합.

---

## 4. 투 포인터 (Two Pointer)

> **30초 요약**: 배열에서 두 개의 포인터(인덱스)를 양 끝 혹은 같은 방향으로 놓고, 조건에 따라 **한 방향으로만 이동**시켜 O(n²) 완전탐색을 O(n)으로 줄이는 기법입니다. "정렬된 배열에서 합이 K인 쌍 찾기", "부분합이 특정 값 이상인 최단 구간" 등에 자주 쓰입니다.

### 일상 비유

한 줄로 선 학생들 중에서 키의 합이 정확히 300cm인 두 학생을 찾는다고 합시다. 키 순으로 줄을 세운 다음, **맨 앞(키 작은)** 학생과 **맨 뒤(키 큰)** 학생을 동시에 가리키고, 합이 크면 뒤쪽을 앞으로, 작으면 앞쪽을 뒤로 한 칸씩 이동합니다. 두 포인터가 만날 때까지 반복하면 O(n)에 끝납니다.

### 시각화 — 합이 K인 쌍 찾기

배열: `[1, 2, 4, 5, 7, 9]`, K = 9

```
단계 1: lo=0(1)  hi=5(9)  합=10 > 9 → hi--
        lo→[1, 2, 4, 5, 7, 9]←hi

단계 2: lo=0(1)  hi=4(7)  합=8  < 9 → lo++
        lo→[1, 2, 4, 5, 7] 9

단계 3: lo=1(2)  hi=4(7)  합=9 == K → 쌍 발견! (2,7) lo++, hi--
           [1, lo→2, 4, 5, 7←hi, 9]

단계 4: lo=2(4)  hi=3(5)  합=9 == K → 쌍 발견! (4,5) lo++, hi--
                 [1, 2, lo→4, 5←hi, 7, 9]

단계 5: lo=3, hi=2 → lo > hi → 종료
```

### 시각화 — 부분합 최단 구간 (슬라이딩 윈도우 변형)

배열: `[2, 3, 1, 2, 4, 3]`, S = 7, 최단 길이 구하기

```
start=0, end=-1, sum=0, ans=INF

end 확장:  [2]         sum=2  < 7
end 확장:  [2,3]       sum=5  < 7
end 확장:  [2,3,1]     sum=6  < 7
end 확장:  [2,3,1,2]   sum=8 >= 7 → ans=4, start 축소
start 축소: [3,1,2]    sum=6  < 7
end 확장:  [3,1,2,4]   sum=10 >= 7 → ans=4, start 축소
start 축소: [1,2,4]    sum=7 >= 7 → ans=3, start 축소
start 축소: [2,4]      sum=6  < 7
end 확장:  [2,4,3]     sum=9 >= 7 → ans=3, start 축소
start 축소: [4,3]      sum=7 >= 7 → ans=2, start 축소
start 축소: [3]        sum=3  < 7
end 확장: 범위 초과 → 종료

최단 길이: 2  ([4,3])
```

### 동작 원리 — 단계별

**패턴 A — 양 끝 투 포인터 (합이 K인 쌍)**
1. 배열을 **오름차순 정렬**.
2. `lo = 0`, `hi = n - 1`로 초기화.
3. `lo < hi`인 동안:
   - `arr[lo] + arr[hi] == K` → 쌍 발견, `lo++`, `hi--`.
   - `arr[lo] + arr[hi] > K` → 합이 너무 큼, `hi--`.
   - `arr[lo] + arr[hi] < K` → 합이 너무 작음, `lo++`.

**패턴 B — 같은 방향 슬라이딩 윈도우 (부분합 최단 구간)**
1. `start = 0`, `end = 0`, 현재 구간 합 `sum = 0`.
2. `end`를 오른쪽으로 늘려가며 `sum += arr[end]`.
3. `sum >= S`가 되면, 구간 길이를 기록하고 `sum -= arr[start]`, `start++`.
4. `end`가 배열 끝을 넘으면 종료.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall -o /tmp/wk2_3.bin /tmp/wk2_3.cpp
#include <bits/stdc++.h>
using namespace std;

// ── 패턴 A: 정렬된 배열에서 a + b = K 인 쌍의 개수 ─────────────────────
int countPairsWithSum(vector<int> arr, int K) {
    sort(arr.begin(), arr.end()); // 반드시 정렬 먼저!

    int lo = 0;
    int hi = (int)arr.size() - 1;
    int count = 0;

    while (lo < hi) {
        int sum = arr[lo] + arr[hi];

        if (sum == K) {
            // 합이 K인 쌍 발견
            // 중복 원소 처리: arr[lo]가 연속으로 같은 값이면 여러 쌍이 생김
            if (arr[lo] == arr[hi]) {
                // lo..hi 사이의 원소가 모두 동일한 경우
                // 그 범위에서 2개를 고르는 조합 수 = (n*(n-1)/2)
                long long n = hi - lo + 1;
                count += (int)(n * (n - 1) / 2);
                break; // 더 이상 볼 필요 없음
            }
            // lo 위치에서 같은 값이 연속되는 수 세기
            int leftCount = 1;
            while (lo + leftCount <= hi && arr[lo + leftCount] == arr[lo])
                leftCount++;
            // hi 위치에서 같은 값이 연속되는 수 세기
            int rightCount = 1;
            while (hi - rightCount >= lo && arr[hi - rightCount] == arr[hi])
                rightCount++;

            count += leftCount * rightCount; // 모든 조합
            lo += leftCount;
            hi -= rightCount;

        } else if (sum < K) {
            lo++; // 합이 작으므로 왼쪽 포인터를 오른쪽으로
        } else {
            hi--; // 합이 크므로 오른쪽 포인터를 왼쪽으로
        }
    }
    return count;
}

// ── 패턴 B: 부분합이 S 이상인 가장 짧은 부분 배열 길이 ─────────────────
// (슬라이딩 윈도우 — 양수 배열에서만 동작)
int shortestSubarrayWithSum(const vector<int>& arr, int S) {
    int n = (int)arr.size();
    int start = 0;
    long long sum = 0;
    int minLen = INT_MAX; // 아직 답 없음

    for (int end = 0; end < n; end++) {
        sum += arr[end]; // 윈도우 오른쪽 확장

        // 합이 S 이상인 동안 왼쪽을 줄여서 최단 구간 탐색
        while (sum >= S) {
            minLen = min(minLen, end - start + 1); // 현재 구간 길이
            sum -= arr[start]; // 왼쪽 원소 제거
            start++;           // 왼쪽 포인터 전진
        }
    }

    // 답이 없으면 0 반환 (문제에 따라 -1 반환하기도 함)
    return (minLen == INT_MAX) ? 0 : minLen;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    // ── 패턴 A 테스트 ─────────────────────────────────────────────────────
    cout << "=== 패턴 A: 합이 K인 쌍 개수 ===\n";

    vector<int> arr1 = {1, 2, 4, 5, 7, 9};
    cout << "배열: 1 2 4 5 7 9\n";
    cout << "K=9인 쌍 개수: " << countPairsWithSum(arr1, 9) << "\n"; // 2: (2,7),(4,5)

    vector<int> arr2 = {1, 3, 3, 3, 5};
    cout << "배열: 1 3 3 3 5 (중복 포함)\n";
    cout << "K=6인 쌍 개수: " << countPairsWithSum(arr2, 6) << "\n"; // 4: (3,3) 세 쌍 + (1,5) 한 쌍

    vector<int> arr3 = {1, 2, 3, 4, 5};
    cout << "배열: 1 2 3 4 5\n";
    cout << "K=10인 쌍 개수: " << countPairsWithSum(arr3, 10) << "\n"; // 0

    // ── 패턴 B 테스트 ─────────────────────────────────────────────────────
    cout << "\n=== 패턴 B: 부분합 >= S인 최단 구간 길이 ===\n";

    vector<int> arr4 = {2, 3, 1, 2, 4, 3};
    cout << "배열: 2 3 1 2 4 3\n";
    cout << "S=7인 최단 구간 길이: " << shortestSubarrayWithSum(arr4, 7) << "\n"; // 2

    vector<int> arr5 = {1, 1, 1, 1, 1, 1, 1};
    cout << "배열: 1 1 1 1 1 1 1\n";
    cout << "S=11인 최단 구간 길이: " << shortestSubarrayWithSum(arr5, 11) << "\n"; // 0 (불가능)

    vector<int> arr6 = {10, 2, 3};
    cout << "배열: 10 2 3\n";
    cout << "S=10인 최단 구간 길이: " << shortestSubarrayWithSum(arr6, 10) << "\n"; // 1

    return 0;
}
```

### 시간/공간 복잡도

| 항목 | 복잡도 | 이유 |
|------|--------|------|
| 패턴 A 시간 | O(n log n) | 정렬 O(n log n) + 탐색 O(n) |
| 패턴 B 시간 | O(n) | `start`, `end` 각각 최대 n번 이동 |
| 공간 | O(1) | 포인터와 합 변수만 사용 (정렬 제외) |

완전 탐색(O(n²))과 비교하면 n = 100,000일 때 10^10 → 10^5 연산으로 줄어듭니다.

### 자주 하는 실수

1. **정렬 생략 (패턴 A)**: 투 포인터 A는 정렬된 배열에서만 작동합니다. 정렬하지 않으면 포인터 이동 방향 판단이 틀려집니다.
2. **슬라이딩 윈도우를 음수 배열에 적용 (패턴 B)**: 원소에 음수가 있으면 `start`를 당겨도 합이 감소하지 않을 수 있습니다. 양수 배열에서만 이 기법이 동작합니다.
3. **`lo < hi` 조건 실수**: `lo == hi`가 되면 같은 원소를 두 번 쓰는 쌍이 됩니다. 반드시 `lo < hi`.
4. **INT_MAX 초기화 후 비교**: `minLen = INT_MAX`로 초기화했다면 반환 전에 `minLen == INT_MAX`인지 확인해 "답 없음"을 0 또는 -1로 반환해야 합니다.

### 연습문제

1. **BOJ 3273 — 두 수의 합**: 정렬 후 양 끝 투 포인터로 a + b = x인 쌍의 수를 구하는 정석 문제.
2. **BOJ 2003 — 수들의 합 2**: 부분합이 M인 구간의 수. 패턴 B 응용.
3. **BOJ 1940 — 주몽**: 두 재료의 합이 M인 쌍 개수. 패턴 A 직접 응용.

---

## 이번 주 핵심 정리

| 알고리즘 | 핵심 아이디어 | 시간 복잡도 | 전제 조건 | 대표 문제 유형 |
|----------|--------------|-------------|----------|----------------|
| 분할 정복 | 반으로 쪼개 재귀 해결 후 합침 | 문제마다 다름 (거듭제곱: O(log n)) | 부분 문제가 같은 구조 | 거듭제곱, 행렬 제곱, 최대 부분합 |
| 병합 정렬 | 분할 후 정렬된 절반을 병합 | O(n log n) (항상) | 없음 | 정렬, 역전 쌍 개수 |
| 이분 탐색 | 정렬된 범위를 절반씩 제거 | O(log n) | 배열이 정렬됨 / 단조성 | 탐색, 최적화 (나무 자르기) |
| 투 포인터 | 두 인덱스를 단방향으로 이동 | O(n) (탐색), O(n log n) (정렬 포함) | 배열 정렬 또는 양수 원소 | 합이 K인 쌍, 최단 부분배열 |

> **기억할 것**: 이분 탐색은 "정렬" 또는 "단조성"만 있으면 쓸 수 있습니다. 투 포인터는 "포인터를 뒤로 되돌릴 필요가 없다"는 확신이 있을 때만 쓰세요. 두 기법 모두 **조건을 만족하는지 검증하는 함수**(check)를 잘 작성하는 것이 핵심입니다. 여러분 모두 잘 할 수 있습니다!
