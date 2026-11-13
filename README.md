# ⚡ Modular Streaming Search Engine (Log-Magnitude Partitioning)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![Language](https://img.shields.io/badge/C%2B%2B-Cython-blue)]()
[![Python](https://img.shields.io/badge/Python-3.8%2B-yellow)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

A high-performance, in-memory streaming data engine built on **Log-Magnitude Modular Partitioning** and **Query-Driven Mathematical Bounding**. Engineered in C++ and exposed via Cython, this architecture bridges the classic database trade-off between ingest-optimized hash tables and query-optimized tree structures.

---

## 🚀 Key Highlights

* **Blazing Ingestion Velocity:** Sustains **>350,000 inserts/sec** with zero tree rebalancing, locking, or background compaction overhead.
* **True $O(1)$ Point Lookups:** Direct arithmetic routing via `(factor, quotient, remainder)` tuples into nested C++ STL hash maps.
* **Query-Driven Range Retrieval ($O(K)$):** Replaces physical tree traversal with closed-form mathematical bounding, achieving **13.45x to 15.80x speedups** over standard Python linear scans.
* **Zero-Copy Memory Access:** Utilizes C++ `const` references (`const std::vector<int64_t>&`) to eliminate redundant heap allocations during query execution.

---

## 🧠 How It Works

### 1. Log-Magnitude Modular Routing (Ingestion)
Instead of forcing incoming records into a globally sorted tree, each integer $x$ is assigned to an exponentially scaling magnitude tier based on its base-10 logarithm:

$$f = 2^{\lfloor \log_{10}(x + 1) \rfloor + 2}$$

The value is then decomposed into a quotient and remainder:

$$q = \lfloor x / f \rfloor, \quad r = x \pmod f$$

Data is stored in a cache-friendly nested C++ container:
```cpp
std::unordered_map<int64_t, std::unordered_map<int64_t, std::vector<int64_t>>> d_sort;
```

### 2. Query-Driven Mathematical Bounding (Range Search)
When executing a range query $[L, U]$, the engine **does not scan** stored partitions. Instead, it analytically computes the exact active factor tiers and quotient boundaries (`q_start` to `q_end`) that mathematically intersect with $[L, U]$, jumping straight to the relevant memory buckets in $O(1)$ time while skipping all out-of-bounds tiers completely.

---

## 📊 Performance Benchmarks

Benchmarks executed on **500,000 random integers** (domain up to $50,000,000$) with a selective range query window $[10,000,000, 15,000,000]$ returning ~50,000 records:

| Method | Avg. Query Latency | Speedup vs. Baseline |
| :--- | :--- | :--- |
| **Standard Python List Scan** | `42.45 ms` | `1.00x` (Baseline) |
| **C++ Modular Engine (`range_search`)** | `3.16 ms` | **`13.45x faster`** |
| **C++ Modular Engine (`range_search_unordered`)** | `2.69 ms` | **`15.80x faster`** |

* **Ingestion Throughput:** 500,000 records inserted in `~0.42s` (~1.18M ops/sec peak C++ loop / >350k ops/sec end-to-end Python stream).

---

## 🛠️ Installation & Build

### Prerequisites
* Python 3.8+
* C++ compiler supporting C++11 or later (`g++`, `clang`, or MSVC)
* Cython (`pip install cython`)

### Compiling the Extension
1. Clone the repository:
   ```bash
   git clone https://github.com/CodersALL/modular-streaming-engine.git
   cd modular-streaming-engine
   ```

2. Build the Cython C++ extension in-place:
   ```bash
   python setup.py build_ext --inplace
   ```

---

## 💻 Quick Start

```python
import bucket_search

# 1. Initialize the C++ Streaming Engine
engine = bucket_search.StreamingModularEngine()

# 2. Stream data in O(1) amortized time
for num in [5, 12, 18, 25, 100, 200, 1001, 1010, 1999]:
    engine.insert(num)

# 3. Point Lookup in O(1) time
exists = engine.search(1010)  # True

# 4. Query-Driven Range Search (Sorted)
sorted_results = engine.range_search(20, 1020)
print("Sorted matches:", sorted_results)

# 5. Query-Driven Range Search (Unordered - Maximum Throughput)
raw_results = engine.range_search_unordered(20, 1020)
print("Unordered matches:", raw_results)
```

---

## 📂 Project Structure

```text
├── bucket_search.pyx               # Core Cython/C++ modular engine implementation
├── setup.py                        # Cython build configuration with -O3 compiler flags
├── benchmark.py                    # Performance comparison suite vs. Python baselines
└── README.md                       # Project documentation
```

---

## 🗺️ Roadmap

- [x] Log-magnitude modular partitioning in C++ STL
- [x] Query-driven mathematical bounding (`range_search`)
- [x] Zero-copy reference optimization & unordered retrieval (`range_search_unordered`)
- [ ] Binary disk serialization & persistence layer
- [ ] Multi-threaded lock-free ingestion pipeline
- [ ] Support for negative integers and floating-point quantization

---

## 📄 Citation

If you use this architecture or reference the findings in your research, please cite:

```bibtex
@article{modular_streaming_engine_2026,
  title={Bypassing the Hash-Tree Trade-Off: A Query-Driven Modular Architecture for High-Throughput Streaming and Range Retrieval},
  author={SOUMYA GHOSH},
  year={2026},
  journal={}
}
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
