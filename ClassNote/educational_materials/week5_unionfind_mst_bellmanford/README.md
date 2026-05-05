# 5주차 — Union-Find, MST(Kruskal/Prim), Bellman-Ford

이번 주에는 **그래프 고급 알고리즘** 세 가지를 배웁니다.

Union-Find(DSU)는 "두 노드가 같은 묶음에 속하는가?"를 O(α(N)) — 사실상 상수 시간 — 에 답해 주는 자료구조입니다. 그 자체로도 유용하지만, Kruskal MST의 핵심 부품으로도 쓰입니다. Kruskal은 간선을 비용 순서대로 하나씩 집어 들면서 "이 간선을 추가하면 사이클이 생기는가?"를 Union-Find로 판단합니다. Prim은 같은 MST 문제를 다른 각도에서 풀어서 — 이미 선택한 정점 집합에서 가장 싼 outgoing edge를 우선순위 큐로 뽑아내는 방식을 사용합니다.

Bellman-Ford는 1주차에 배운 Dijkstra와 같은 "최단 경로" 문제를 다루지만, **음수 가중치 간선**을 처리할 수 있다는 결정적 차이가 있습니다. 대신 속도는 O(VE)로 Dijkstra보다 느립니다. 또한 음수 사이클이 존재하는 경우를 탐지할 수 있어서, "무한히 비용을 줄일 수 있는 경로가 있는가?"를 판별하는 데도 쓰입니다.

---

## 목차

1. [Union-Find (Disjoint Set Union)](#1-union-find-disjoint-set-union)
2. [Kruskal MST](#2-kruskal-mst-크루스칼-최소-신장-트리)
3. [Prim MST](#3-prim-mst-프림-최소-신장-트리)
4. [Bellman-Ford](#4-bellman-ford-벨만-포드)
5. [이번 주 핵심 정리](#이번-주-핵심-정리)

---

## 1. Union-Find (Disjoint Set Union)

> **30초 요약**: 여러 원소를 겹치지 않는 집합들로 관리한다. `find(x)` — x가 속한 집합의 대표를 반환, `union(x, y)` — x와 y의 집합을 합친다. 경로 압축 + 랭크 기반 합치기를 함께 쓰면 거의 O(1).

### 일상 비유

학교 전체 학생을 동아리별로 묶는 상황을 생각해 보세요. 처음에는 모두가 각자 "혼자만의 동아리"입니다. 두 학생이 같은 동아리에 합류하면 두 집합이 하나로 합쳐집니다. 나중에 "A와 B가 같은 동아리인가?"를 물어볼 때, 각자의 **동아리 대표**를 찾아 비교하면 됩니다. Union-Find는 이 대표 찾기와 합치기를 매우 빠르게 수행합니다.

### 시각화

초기 상태 (각자가 대표):

```
0   1   2   3   4
↓   ↓   ↓   ↓   ↓
0   1   2   3   4
(parent[i] = i)
```

`union(0,1)`, `union(1,2)` 후 (**rank 미적용** — 사슬 형성으로 경로 압축 효과를 보이기 위한 예시):

```
  0
  |
  1
  |
  2         3   4

parent: [0, 0, 1, 3, 4]   ← rank 없이 단순 union: parent[2]=1, parent[1]=0
rank:   [1, 0, 0, 0, 0]   ← union by rank 적용 시엔 rank[0]=1이 올바름
```

> **참고**: 실제 코드는 union by rank를 적용하므로 `union(0,1)` 후 `parent[1]=0, rank[0]=1`, `union(1,2)` 호출 시 `find(1)=0`, `find(2)=2`이므로 `parent[2]=0`이 되어 트리가 바로 납작해집니다. 위 그림은 rank를 적용하지 않은 단순 union의 경우로, 사슬이 생겼을 때 경로 압축이 얼마나 효과적인지 보여 주기 위한 시나리오입니다.

`find(2)` — 경로 압축 전 (사슬 시나리오):

```
2 → 1 → 0   (두 번 점프)
```

`find(2)` — 경로 압축 후:

```
2 → 0   (바로 연결됨, 이후 find(2)는 O(1))
parent: [0, 0, 0, 3, 4]   ← 2가 루트 0에 직접 연결
```

### 동작 원리 — 단계별

1. **초기화**: `parent[i] = i`, `rank[i] = 0` — 모든 노드가 자기 자신의 대표.
2. **find(x)**: `parent[x] == x`이면 x를 반환. 아니면 `parent[x] = find(parent[x])` — 재귀 호출하면서 경로상의 모든 노드를 루트에 직접 연결(경로 압축).
3. **union(x, y)**: 각각의 대표 `rx = find(x)`, `ry = find(y)`를 구한다. `rx == ry`이면 이미 같은 집합(아무것도 안 함). 다르면 랭크가 낮은 쪽을 높은 쪽 아래에 붙인다. 랭크가 같으면 한쪽을 붙이고 그 루트의 랭크를 +1.
4. **same(x, y)**: `find(x) == find(y)` — 같은 집합이면 true.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall 통과
#include <bits/stdc++.h>
using namespace std;

// ─────────────────────────────────────────────
//  Union-Find (Disjoint Set Union) 구현
// ─────────────────────────────────────────────
struct DSU {
    vector<int> parent; // parent[i]: i의 부모 노드
    vector<int> rank_;  // rank_[i]: i를 루트로 하는 트리의 (대략적) 높이

    // n개의 원소로 초기화 — 각자가 독립된 집합
    DSU(int n) : parent(n), rank_(n, 0) {
        iota(parent.begin(), parent.end(), 0); // parent[i] = i
    }

    // x가 속한 집합의 대표(루트)를 반환
    // 경로 압축: 재귀 도중 만나는 모든 노드를 루트에 직접 연결
    int find(int x) {
        if (parent[x] != x)
            parent[x] = find(parent[x]); // ← 경로 압축 핵심
        return parent[x];
    }

    // x의 집합과 y의 집합을 합친다 (union by rank)
    // 이미 같은 집합이면 false 반환
    bool unite(int x, int y) {
        int rx = find(x), ry = find(y);
        if (rx == ry) return false; // 이미 같은 집합 → 합치지 않음

        // 랭크가 낮은 쪽을 높은 쪽 아래에 붙여서 트리를 납작하게 유지
        if (rank_[rx] < rank_[ry]) swap(rx, ry);
        parent[ry] = rx; // ry를 rx 아래에 붙임
        if (rank_[rx] == rank_[ry]) rank_[rx]++; // 같은 랭크일 때만 증가
        return true;
    }

    // x와 y가 같은 집합인가?
    bool same(int x, int y) { return find(x) == find(y); }
};

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // 노드 0~5, 6개 원소
    DSU dsu(6);

    // 집합 합치기
    dsu.unite(0, 1); // {0,1}, {2}, {3}, {4}, {5}
    dsu.unite(1, 2); // {0,1,2}, {3}, {4}, {5}
    dsu.unite(3, 4); // {0,1,2}, {3,4}, {5}

    // 쿼리
    cout << "0과 2는 같은 집합? " << (dsu.same(0, 2) ? "YES" : "NO") << "\n"; // YES
    cout << "0과 3은 같은 집합? " << (dsu.same(0, 3) ? "YES" : "NO") << "\n"; // NO
    cout << "3과 4는 같은 집합? " << (dsu.same(3, 4) ? "YES" : "NO") << "\n"; // YES

    // 추가 합치기
    dsu.unite(2, 3); // {0,1,2,3,4}, {5}
    cout << "0과 4는 같은 집합? " << (dsu.same(0, 4) ? "YES" : "NO") << "\n"; // YES
    cout << "0과 5는 같은 집합? " << (dsu.same(0, 5) ? "YES" : "NO") << "\n"; // NO

    return 0;
}
```

### 시간/공간 복잡도

| 연산 | 복잡도 |
|------|--------|
| `find(x)` | O(α(N)) ≈ O(1) (경로 압축 + 랭크 결합 시) |
| `unite(x, y)` | O(α(N)) ≈ O(1) |
| 공간 | O(N) |

α(N)은 역 아커만 함수로, 실용적인 N 범위(N ≤ 2^65536 수준)에서 4를 넘지 않을 만큼 극도로 천천히 증가합니다(Tarjan 1975). 이 복잡도는 **amortized**(분할 상환) 비용입니다 — 개별 연산이 가끔 더 오래 걸릴 수 있지만, M번 연산의 총 비용이 O(M · α(N))임을 의미합니다.

**경로 압축과 union by rank의 시너지**: rank만 사용하면 트리 높이가 O(log N)으로 보장됩니다. 경로 압축은 find 경로상의 모든 노드를 루트에 직접 연결해 이후 find를 거의 O(1)로 만듭니다. 두 기법을 결합하면 트리가 점점 납작해지며 amortized O(α(N))이 달성됩니다.

### 자주 하는 실수

1. **경로 압축만 쓰고 union by rank를 빠뜨리기** — 경로 압축 없이 rank만 있어도 O(log N), 둘 다 있어야 O(α(N))입니다. 한쪽만 구현하는 경우가 많습니다.
2. **union 시 `parent[x] = y`로 대표가 아닌 원소에 직접 붙이기** — 반드시 `find(x)`와 `find(y)`의 루트끼리 연결해야 합니다. `parent[x] = y`처럼 루트가 아닌 곳에 붙이면 구조가 망가집니다.
3. **0-indexed vs 1-indexed 혼용** — 문제마다 노드 번호가 1부터 시작하는 경우가 많습니다. DSU 크기를 `n+1`로 만들거나, 입력을 0-indexed로 변환하는 것을 잊지 마세요.

### 연습문제

1. **백준 1717 — 집합의 표현**: Union-Find 기본 문제. `0 a b`이면 a와 b를 합치고, `1 a b`이면 같은 집합인지 출력.
2. **백준 4195 — 친구 네트워크**: 이름(문자열) → 번호 매핑(map) 후 DSU 적용. 합칠 때마다 집합 크기도 함께 관리.

---

## 2. Kruskal MST (크루스칼 최소 신장 트리)

> **30초 요약**: 모든 간선을 가중치 오름차순으로 정렬한 뒤, 사이클을 만들지 않는 간선만 골라 N-1개를 추가한다. 사이클 검사는 Union-Find로 O(α(N)).

### 일상 비유

여러 마을을 연결하는 도로망을 가장 싼 비용으로 깔아야 한다고 상상해 보세요. 가장 저렴한 공사 구간부터 허가합니다. 단, "이 구간을 뚫으면 이미 연결된 두 마을 사이에 우회로가 생기는가?"(= 사이클)를 확인하고, 그렇다면 건너뜁니다. N개의 마을을 연결하려면 정확히 N-1개의 도로가 필요합니다.

### 시각화

```
그래프 (5개 정점, 7개 간선):

    1
   /|\
  2  | 4
 /   |  \
2    3    3
 \   |   /
  3--+--4
     |
     5

간선 목록 (정렬 후):
(1,2,1) (3,4,1) (2,3,2) (1,3,4) (2,4,3) (1,4,3) (3,5,5)

단계:
① (1,2,1) 추가 → find(1)≠find(2), unite → MST 간선
② (3,4,1) 추가 → find(3)≠find(4), unite → MST 간선
③ (2,3,2) 추가 → find(2)≠find(3), unite → MST 간선
④ (1,3,4) 건너뜀 → find(1)==find(3) (이미 같은 집합, 사이클!)
⑤ (2,4,3) 건너뜀 → find(2)==find(4)
⑥ (1,4,3) 건너뜀 → find(1)==find(4)
⑦ (3,5,5) 추가 → find(3)≠find(5), unite → MST 간선 (N-1=4개 완성)

MST 총 비용: 1+1+2+5 = 9
```

### 동작 원리 — 단계별

1. 모든 간선을 `(비용, u, v)` 형태로 저장하고 비용 기준 오름차순 정렬.
2. DSU를 초기화한다 (노드 수 N).
3. 간선을 순서대로 꺼낸다:
   - `find(u) == find(v)`: 이미 같은 집합 → 이 간선을 추가하면 사이클 → 건너뜀.
   - `find(u) != find(v)`: 서로 다른 집합 → `unite(u, v)`, MST에 추가, 비용 누적.
4. MST 간선이 N-1개가 되면 종료.
5. 간선이 부족해 N-1개를 못 채우면 그래프가 비연결 — MST 없음.

### 왜 옳은가? (Cut Property)

> **Cut property (절단 성질)**: 정점들을 두 그룹 S, V\S로 나누는 어떤 cut에서 그 cut을 가로지르는 간선들 중 **가중치가 가장 작은 간선**은 어떤 MST에든 반드시 포함된다.

직관: 어떤 MST가 그 최소 가중치 간선 e를 사용하지 않는다고 가정하자. e의 양끝은 다른 경로 P로 연결돼 있어야 하고, P는 cut을 어딘가에서 가로지른다 — 그 가로지르는 간선 e' 의 가중치는 e 이상. e' 를 e로 바꿔도 여전히 트리이고 비용은 늘지 않는다 → 모순(또는 동일 비용의 다른 MST).

Kruskal이 가중치 오름차순으로 간선을 검사할 때, "사이클을 만들지 않는 첫 간선"은 그 시점에서 자동으로 **이미 합쳐진 어떤 컴포넌트와 그 외부 사이의 cut에서 최소 가중치 간선**이 된다. cut property에 의해 안전하게 추가할 수 있다 — 이를 반복하면 MST가 완성된다.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall 통과
#include <bits/stdc++.h>
using namespace std;

// ─── DSU (위와 동일) ──────────────────────────
struct DSU {
    vector<int> parent, rank_;
    DSU(int n) : parent(n), rank_(n, 0) {
        iota(parent.begin(), parent.end(), 0);
    }
    int find(int x) {
        if (parent[x] != x) parent[x] = find(parent[x]);
        return parent[x];
    }
    bool unite(int x, int y) {
        int rx = find(x), ry = find(y);
        if (rx == ry) return false;
        if (rank_[rx] < rank_[ry]) swap(rx, ry);
        parent[ry] = rx;
        if (rank_[rx] == rank_[ry]) rank_[rx]++;
        return true;
    }
};

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // 정점 5개(1-indexed), 간선 7개
    int N = 5;
    // {가중치, u, v} 형태
    vector<tuple<int,int,int>> edges = {
        {1, 1, 2}, {1, 3, 4}, {2, 2, 3},
        {4, 1, 3}, {3, 2, 4}, {3, 1, 4}, {5, 3, 5}
    };

    // 간선을 가중치 오름차순 정렬 (tuple 기본 비교: 첫 원소 기준)
    sort(edges.begin(), edges.end());

    DSU dsu(N + 1); // 1-indexed이므로 N+1 크기
    long long mst_cost = 0;
    int edge_count = 0;

    for (auto& [w, u, v] : edges) {
        if (dsu.unite(u, v)) {          // 사이클이 생기지 않을 때만 추가
            mst_cost += w;
            edge_count++;
            cout << "간선 (" << u << "-" << v << ", 비용 " << w << ") 추가\n";
        } else {
            cout << "간선 (" << u << "-" << v << ", 비용 " << w << ") 사이클 → 건너뜀\n";
        }
        if (edge_count == N - 1) break; // MST 완성
    }

    if (edge_count < N - 1) {
        cout << "MST 불가: 그래프가 연결되어 있지 않습니다.\n";
    } else {
        cout << "\nMST 총 비용: " << mst_cost << "\n"; // 9
    }

    return 0;
}
```

### 시간/공간 복잡도

| 단계 | 복잡도 |
|------|--------|
| 간선 정렬 | O(E log E) |
| Union-Find 처리 | O(E · α(V)) ≈ O(E) |
| 전체 | **O(E log E)** |
| 공간 | O(E + V) |

간선 수 E가 적을 때(희소 그래프) Kruskal이 유리합니다.

### 자주 하는 실수

1. **정렬을 빠뜨리거나 내림차순으로 정렬하기** — 반드시 가중치 오름차순이어야 합니다. 내림차순 정렬은 최대 신장 트리가 됩니다.
2. **N-1개 완성 후에도 계속 순회하기** — 불필요한 DSU 연산이 생기며, 간선 수가 매우 많으면 시간 초과 원인이 됩니다. `edge_count == N-1`이 되면 바로 `break`.
3. **1-indexed 입력에 0-indexed DSU 사용** — DSU 크기를 `N+1`로 만들거나 입력에서 1을 빼서 0-indexed로 정규화하세요.

### 연습문제

1. **백준 1197 — 최소 스패닝 트리**: Kruskal/Prim 모두 가능. MST 가중치 합 출력.
2. **백준 1922 — 네트워크 연결**: 1197과 거의 동일한 구조. 컴퓨터를 최소 비용으로 모두 연결.

---

## 3. Prim MST (프림 최소 신장 트리)

> **30초 요약**: 시작 정점 하나를 MST에 넣고, MST와 연결된 간선 중 가장 작은 것을 반복해서 추가한다. 우선순위 큐(최소 힙)로 O((V+E) log V).

### 일상 비유

도시 외곽에서 출발해 도로를 하나씩 깔아 나간다고 생각하세요. 현재 연결된 구역에서 뻗어 나갈 수 있는 도로들을 모두 후보로 올려 두고, 그 중 가장 싼 도로를 선택합니다. 이미 연결된 구역으로 가는 도로는 버립니다. 모든 구역이 연결될 때까지 반복합니다. Kruskal이 "전체 간선 목록에서 골라내기"라면, Prim은 "현재 연결 구역에서 바깥으로 뻗어나가기"입니다.

### 시각화

```
그래프 (Kruskal 예시와 동일):
정점: 1 2 3 4 5
간선: (1,2,1) (3,4,1) (2,3,2) (1,3,4) (2,4,3) (1,4,3) (3,5,5)

시작: 정점 1, visited={1}, PQ=[(1,2),(4,3),(3,4)]

① PQ에서 (1,2) 꺼냄 → 2 미방문 → visited={1,2}
   PQ에 2의 이웃 추가: (2,3), (3,4)
② PQ에서 (2,3) 꺼냄 → 3 미방문 → visited={1,2,3}
   PQ에 3의 이웃 추가: (1,4), (5,5)
③ PQ에서 (1,4) 꺼냄 → 4 미방문 → visited={1,2,3,4}
   PQ에 4의 이웃 추가: (3,2)→이미방문 무시
④ PQ에서 (5,5) 꺼냄 → 5 미방문 → visited={1,2,3,4,5}

MST 간선: (1,2,1),(2,3,2),(3,4,1),(3,5,5) → 총 비용 9
```

### 동작 원리 — 단계별

1. 임의의 시작 정점 s를 선택. `dist[s] = 0`, 나머지 `dist[i] = INF`.
2. 최소 힙(priority_queue)에 `(0, s)` 삽입.
3. 힙이 빌 때까지:
   - `(cost, u)` 꺼낸다.
   - u가 이미 방문됐으면 건너뜀(지연 삭제 방식).
   - u를 방문 처리, MST 비용에 cost 추가.
   - u의 모든 이웃 v에 대해: v가 미방문이고 간선 가중치 w < dist[v]이면 `dist[v] = w`로 갱신하고 힙에 `(w, v)` 삽입.
4. 모든 V개 정점을 방문하면 종료.

### 왜 옳은가? (Prim도 Cut Property)

Prim은 매 단계마다 자연스러운 cut을 만든다 — `S = 지금까지 방문한 정점`, `V \ S = 미방문`. 우선순위 큐가 꺼내는 `(최소 cost, u)`는 정확히 **이 cut을 가로지르는 간선들 중 최소 가중치 간선**이다. 따라서 cut property에 의해 안전하다. Kruskal과 Prim은 같은 cut property를 다른 방식(전역 정렬 vs 지역 frontier 확장)으로 활용하는 두 얼굴이다.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall 통과
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // 정점 5개(1-indexed), 양방향 간선
    int N = 5;
    // adj[u] = {(가중치, v), ...}
    vector<vector<pair<int,int>>> adj(N + 1);

    auto add_edge = [&](int u, int v, int w) {
        adj[u].push_back({w, v});
        adj[v].push_back({w, u}); // 무방향 그래프
    };
    add_edge(1, 2, 1);
    add_edge(3, 4, 1);
    add_edge(2, 3, 2);
    add_edge(1, 3, 4);
    add_edge(2, 4, 3);
    add_edge(1, 4, 3);
    add_edge(3, 5, 5);

    // Prim 알고리즘
    vector<bool> visited(N + 1, false);
    // 최소 힙: {가중치, 정점}
    priority_queue<pair<int,int>, vector<pair<int,int>>, greater<>> pq;

    pq.push({0, 1}); // 시작 정점 1, 비용 0
    long long mst_cost = 0;
    int visited_count = 0;

    while (!pq.empty() && visited_count < N) {
        auto [cost, u] = pq.top(); pq.pop();

        if (visited[u]) continue; // 이미 MST에 포함된 정점 → 건너뜀
        visited[u] = true;
        mst_cost += cost;
        visited_count++;
        cout << "정점 " << u << " MST 편입 (간선 비용: " << cost << ")\n";

        // u의 이웃을 힙에 추가
        for (auto [w, v] : adj[u]) {
            if (!visited[v]) {        // 아직 MST에 없는 정점만 추가
                pq.push({w, v});
            }
        }
    }

    if (visited_count < N) {
        cout << "MST 불가: 그래프가 연결되어 있지 않습니다.\n";
    } else {
        cout << "\nMST 총 비용: " << mst_cost << "\n"; // 9
    }

    return 0;
}
```

### 시간/공간 복잡도

| 구현 방식 | 복잡도 |
|-----------|--------|
| 우선순위 큐(이진 힙) | **O((V + E) log V)** |
| 인접 행렬 + 선형 탐색 | O(V²) — 밀집 그래프에 유리 |
| 공간 | O(V + E) |

간선 수 E가 많을 때(밀집 그래프) Prim이 Kruskal보다 유리할 수 있습니다.

### Kruskal vs Prim 비교

| | Kruskal | Prim |
|--|---------|------|
| 핵심 도구 | Union-Find + 정렬 | 우선순위 큐 |
| 복잡도 | O(E log E) | O((V+E) log V) |
| 유리한 경우 | 희소 그래프 (E가 적음) | 밀집 그래프 (E가 많음) |
| 구현 난이도 | 쉬움 | 약간 복잡 |

### 자주 하는 실수

1. **방문 체크 없이 힙에서 꺼낸 정점을 그냥 처리하기** — 힙에는 같은 정점이 여러 번 들어갈 수 있습니다(지연 삭제 방식). 방문 여부를 확인하지 않으면 비용이 중복 누적됩니다.
2. **무방향 그래프인데 한쪽 방향만 추가하기** — `add_edge(u, v, w)`와 `add_edge(v, u, w)` 둘 다 추가해야 합니다.
3. **힙의 pair 순서 — `{정점, 비용}` vs `{비용, 정점}`** — `priority_queue`는 기본이 최대 힙입니다. `greater<>`와 함께 `{비용, 정점}` 순서로 넣어야 최소 비용이 먼저 나옵니다. 순서가 바뀌면 정점 번호 기준으로 정렬됩니다.

### 연습문제

1. **백준 1197 — 최소 스패닝 트리**: Prim으로도 풀어 보세요. Kruskal 풀이와 비교.
2. **백준 17472 — 다리 만들기 2**: BFS로 섬 번호를 매긴 뒤 MST 적용. 제약이 있어서 구현 난이도가 높습니다.

---

## 4. Bellman-Ford (벨만-포드)

> **30초 요약**: 시작 정점에서 모든 정점까지 최단 거리를 구한다. V-1번 동안 모든 간선을 완화(relax)한다. 음수 가중치 간선 허용. V번째 완화에서 갱신이 일어나면 음수 사이클 존재.

### 일상 비유

지도의 모든 도로를 V-1번 반복해서 "이 도로를 거치면 더 짧아지는 경로가 있나?"를 확인합니다. 처음에는 출발지만 0이고 나머지는 무한대입니다. 매 라운드마다 갱신이 일어나며 경로가 점점 짧아집니다. V-1번 후에는 최단 경로가 확정됩니다(최단 경로는 최대 V-1개의 간선을 사용하기 때문). 만약 V번째 라운드에도 갱신이 된다면, 빙빙 돌수록 비용이 줄어드는 음수 사이클이 있다는 뜻입니다.

### 시각화

```
그래프 (정점 5개, 음수 간선 포함):

  0 ──(6)──> 1
  |          |
 (7)       (-2)
  |          |
  v          v
  3 <─(5)── 2
  |
 (-3)
  |
  v
  4

간선: (0→1,6),(0→3,7),(1→2,5),(1→3,8),(1→4,-4),(2→0,-2),(3→2,-3),(3→4,9),(4→2,7)

초기: dist = [0, INF, INF, INF, INF]

라운드 1 (모든 간선 완화):
  0→1: dist[1] = min(INF, 0+6) = 6
  0→3: dist[3] = min(INF, 0+7) = 7
  1→2: dist[2] = min(INF, 6+5) = 11
  1→3: dist[3] = min(7, 6+8) = 7
  1→4: dist[4] = min(INF, 6-4) = 2
  2→0: dist[0] = min(0, 11-2) = 0 (갱신 없음)
  3→2: dist[2] = min(11, 7-3) = 4
  3→4: dist[4] = min(2, 7+9) = 2
  4→2: dist[2] = min(4, 2+7) = 4

라운드 2에서는 모든 간선이 추가 갱신을 만들지 않아 조기 종료된다.
최종 dist = [0, 6, 4, 7, 2]
```

### 동작 원리 — 단계별

1. `dist[src] = 0`, 나머지 `dist[i] = INF`.
2. **V-1번** 반복:
   - 모든 간선 `(u, v, w)`에 대해: `dist[u] + w < dist[v]`이면 `dist[v] = dist[u] + w` (완화).
3. **V번째** 반복: 모든 간선에 대해 완화 시도. 하나라도 갱신되면 **음수 사이클 존재**.
4. `dist[i]`가 INF이면 src에서 i로 도달 불가.

**왜 V-1번이면 충분한가?** 음수 사이클이 없다고 가정하면, 최단 경로는 같은 정점을 두 번 지나지 않는 단순 경로(simple path)이고, 단순 경로의 간선 수는 최대 V-1입니다. V-1번 라운드면 길이 ≤ V-1인 모든 경로가 확정됩니다.

**왜 V번째 라운드의 갱신 = 음수 사이클인가?** V-1번 완화 후에도 또 갱신이 일어난다면, 더 짧아지려는 경로가 V개 이상의 간선을 사용한다는 뜻입니다. V개 간선 = 비둘기집 원리에 의해 어떤 정점을 두 번 지나는 경로 = 사이클을 한 번 이상 돈 경로. 그 사이클을 돌수록 비용이 줄어들었다면 음수 사이클입니다.

> 주의: 위 코드는 `dist[u] == INF`를 가드로 두므로 **src에서 도달 가능한 음수 사이클**만 탐지합니다. 그래프 전체에서 음수 사이클을 찾으려면 모든 정점의 `dist[i]`를 0으로 초기화해야 합니다.

### C++ 코드

```cpp
// g++ -std=c++17 -Wall 통과
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // 정점 5개(0-indexed), 간선 목록
    int V = 5;
    // {u, v, 가중치} 형태의 방향 간선
    vector<tuple<int,int,int>> edges = {
        {0, 1,  6}, {0, 3,  7},
        {1, 2,  5}, {1, 3,  8}, {1, 4, -4},
        {2, 0, -2},
        {3, 2, -3}, {3, 4,  9},
        {4, 2,  7}
    };

    const long long INF = 1e18; // 충분히 큰 값 (int 오버플로 방지를 위해 long long)
    int src = 0; // 시작 정점
    vector<long long> dist(V, INF);
    dist[src] = 0;

    // ─── V-1번 완화 ──────────────────────────────
    for (int round = 1; round <= V - 1; round++) {
        bool updated = false; // 이번 라운드에 갱신 있었는가?
        for (auto& [u, v, w] : edges) {
            // dist[u]가 INF이면 u에서 출발하는 완화는 의미 없음 (오버플로 방지)
            if (dist[u] == INF) continue;
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                updated = true;
            }
        }
        // 조기 종료: 이번 라운드에 갱신이 없으면 이후도 없음
        if (!updated) {
            cout << "라운드 " << round << "에서 수렴 (조기 종료)\n";
            break;
        }
    }

    // ─── V번째 완화: 음수 사이클 탐지 ──────────
    bool has_negative_cycle = false;
    for (auto& [u, v, w] : edges) {
        if (dist[u] == INF) continue;
        if (dist[u] + w < dist[v]) {
            has_negative_cycle = true;
            break; // 하나라도 갱신되면 음수 사이클 확정
        }
    }

    if (has_negative_cycle) {
        cout << "경고: 음수 사이클이 존재합니다! 최단 경로를 정의할 수 없습니다.\n";
        return 0;
    }

    // 최단 거리 출력
    cout << "정점 " << src << "에서 각 정점까지 최단 거리:\n";
    for (int i = 0; i < V; i++) {
        if (dist[i] == INF)
            cout << "  " << src << " → " << i << ": 도달 불가\n";
        else
            cout << "  " << src << " → " << i << ": " << dist[i] << "\n";
    }
    // 기대 출력: 0→0:0, 0→1:6, 0→2:4, 0→3:7, 0→4:2 (라운드 2에서 수렴)

    return 0;
}
```

### 음수 사이클이 있는 예시

```cpp
// g++ -std=c++17 -Wall 통과
#include <bits/stdc++.h>
using namespace std;

int main() {
    // 정점 3개, 음수 사이클: 0→1→2→0 총 가중치 -1
    int V = 3;
    vector<tuple<int,int,int>> edges = {
        {0, 1, 1}, {1, 2, -3}, {2, 0, 1}
        //           ↑ 사이클 합: 1 + (-3) + 1 = -1 (음수!)
    };

    const long long INF = 1e18;
    vector<long long> dist(V, INF);
    dist[0] = 0;

    for (int round = 1; round <= V - 1; round++) {
        for (auto& [u, v, w] : edges) {
            if (dist[u] != INF && dist[u] + w < dist[v])
                dist[v] = dist[u] + w;
        }
    }

    // V번째 완화로 음수 사이클 탐지
    bool neg_cycle = false;
    for (auto& [u, v, w] : edges) {
        if (dist[u] != INF && dist[u] + w < dist[v]) {
            neg_cycle = true;
            break;
        }
    }

    if (neg_cycle)
        cout << "음수 사이클 발견! 최단 경로 무한히 작아질 수 있습니다.\n";
    else
        cout << "음수 사이클 없음.\n";

    return 0;
}
```

### 시간/공간 복잡도

| | 복잡도 |
|--|--------|
| 시간 | **O(V · E)** |
| 공간 | O(V + E) |
| Dijkstra 비교 | Dijkstra: O((V+E) log V), 음수 간선 불가 |

Bellman-Ford는 느리지만 음수 가중치와 음수 사이클 탐지가 필요할 때 사용합니다.

### Bellman-Ford vs Dijkstra 비교

| | Bellman-Ford | Dijkstra |
|--|-------------|---------|
| 음수 가중치 | 허용 | 불가 |
| 음수 사이클 탐지 | 가능 | 불가 |
| 시간 복잡도 | O(VE) | O((V+E) log V) |
| 사용 조건 | 음수 간선 있을 때 | 모든 가중치 ≥ 0 |

### 자주 하는 실수

1. **dist[u] == INF 체크 생략** — `dist[u]`가 INF일 때 `dist[u] + w`를 계산하면 long long 오버플로가 발생할 수 있습니다. 반드시 `if (dist[u] == INF) continue;` 를 넣으세요.
2. **V번째 완화를 빠뜨려 음수 사이클을 탐지 못하기** — V-1번 루프만 쓰고 끝내면 음수 사이클 여부를 알 수 없습니다. 문제에서 음수 사이클 탐지를 요구하는 경우 반드시 추가하세요.
3. **양방향 간선을 단방향으로만 추가하기** — Bellman-Ford는 간선 목록을 직접 다루므로, 무방향 그래프라면 `(u,v,w)`와 `(v,u,w)` 둘 다 edges에 넣어야 합니다.
4. **int 사용 — 가중치 합산 오버플로** — 가중치나 거리 값이 클 경우 `int` 범위를 초과합니다. `long long`을 사용하고 INF를 `1e18` 또는 `LLONG_MAX/2`로 설정하세요.

### 연습문제

1. **백준 11657 — 타임머신**: Bellman-Ford 기본 문제. 음수 사이클이 있으면 -1 출력.
2. **백준 1219 — 오민식의 고민**: 최대값 경로 + 양수 사이클 탐지 (부호를 반전하면 Bellman-Ford 응용).

---

## 이번 주 핵심 정리

| 알고리즘 | 언제 쓰나 | 시간 복잡도 | 핵심 주의사항 |
|----------|-----------|-------------|---------------|
| **Union-Find** | "두 노드가 같은 집합인가?", 집합 병합 쿼리 | O(α(N)) ≈ O(1) | 경로 압축 + union by rank 둘 다 필요 |
| **Kruskal MST** | 최소 신장 트리, 희소 그래프 | O(E log E) | 간선 정렬 필수, N-1개 완성 시 break |
| **Prim MST** | 최소 신장 트리, 밀집 그래프 | O((V+E) log V) | 방문 체크 필수, 힙에 {비용, 정점} 순서 |
| **Bellman-Ford** | 음수 가중치 최단 경로, 음수 사이클 탐지 | O(V · E) | INF 체크로 오버플로 방지, V번째 완화로 음수 사이클 판별 |

### 알고리즘 선택 가이드

```
최단 경로가 필요한가?
├─ 음수 가중치 있음 → Bellman-Ford
└─ 음수 가중치 없음 → Dijkstra (1주차)

모든 정점을 연결하는 최소 비용 트리가 필요한가? (MST)
├─ 희소 그래프 (E ≈ V) → Kruskal
└─ 밀집 그래프 (E ≈ V²) → Prim

두 노드가 같은 그룹인가? / 집합 병합이 필요한가?
└─ Union-Find (DSU)
   └─ Kruskal 내부에도 사용됨
```

### 복잡도 한눈에

```
V = 정점 수, E = 간선 수, α = 역 아커만 (≈ 상수)

Union-Find:  O(α(N)) per query
Kruskal:     O(E log E)
Prim:        O((V+E) log V)
Bellman-Ford: O(V·E)
Dijkstra:    O((V+E) log V)  ← 복습
```
