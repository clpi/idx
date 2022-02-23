#include <thread>
#include <iostream>
#include <string>
#include <limits>
#include <set>
#include <map>
#include <vector>
#include <queue>
#include <utility>
#include <algorithm>
#include <iterator>
#include <list>
using namespace std;

typedef int vtx_t;
typedef double weight_t;
const weight_t max_weight = std::numeric_limits<double>::infinity();
struct neighbor {
    vtx_t target;
    weight_t weight;
    neighbor(vtx_t arg_target, weight_t arg_weight) : target(arg_target), weight(arg_weight) { };
};
typedef std::vector<neighbor> neighbors_t;
typedef std::vector<neighbors_t > adj_list_t;

class Graph {
public:
    Graph(int V);
    int node_capacity;
    std::list<int> *adjl;

    void addEdge(int v, int w);

    void bfs(int v);
    void dfs(int v);
};
Graph::Graph(int v) {
    this->node_capacity = v;
    adjl = new list<int>[node_capacity];
}

void Graph::addEdge(int v, int w) {
    adjl[v].push_back(w);
}

void Graph::bfs(int v) {
    bool *visited = new bool[node_capacity];
    for (int i = 0; i < v; i++)
        visited[i] = false;
    list<int> queue;
    visited[v] = true;
    queue.push_back(v);
    list<int>::iterator i;
    while(!queue.empty()) {
        v = queue.front();
        cout << v << " ";
        queue.pop_front();
        for (i = adjl[v].begin(); i != adjl[v].end(); ++i) {
            if (!visited[*i]) {
                visited[*i] = true;
                queue.push_back(*i);
            }

        }
    }
}
/// Make work
void Graph::dfs(int v) {
    bool *visited = new bool[node_capacity];
    for (int i = 0; i < v; i++)
        visited[i] = false;
    list<int> queue;
    visited[v] = true;
    queue.push_back(v);
    list<int>::iterator i;
    while (!queue.empty()) {
        v = queue.front();
        cout << v << " ";
        for (i = adjl[v].begin(); i != adjl[v].end(); ++i) {
            if (!visited[*i]) {
                visited[*i] = true;
                queue.push_back(v);
                dfs(*i);
            }
        }
    }
}
int graphTest() {
    Graph g(20);
    g.addEdge(0, 1);
    g.addEdge(0, 2);
    g.addEdge(1, 2);
    g.addEdge(2, 0);
    g.addEdge(2, 3);
    g.addEdge(3, 3);
    cout << "Following is Breadth First Traversal";
    g.bfs(2);
    return 0;
}


int main() {
    graphTest();
}
