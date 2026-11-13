import time
import random
import bucket_search

def run_benchmark():
    n_records = 500_000
    print(f"Generating {n_records:,} random integers for streaming insertion...")
    
    # Generate test data
    raw_data = [random.randint(1, 50_000_000) for _ in range(n_records)]
    
    # 1. Populate C++ Modular Engine
    print("Populating StreamingModularEngine (C++)...")
    engine = bucket_search.StreamingModularEngine()
    start = time.perf_counter()
    for num in raw_data:
        engine.insert(num)
    cpp_insert_time = time.perf_counter() - start
    print(f"C++ Insertion Time: {cpp_insert_time:.4f}s")

    # 2. Populate Standard Python List
    print("Populating standard Python list...")
    start = time.perf_counter()
    py_list = list(set(raw_data)) # deduplicate to match set-like behavior
    py_insert_time = time.perf_counter() - start
    print(f"Python List Creation Time: {py_insert_time:.4f}s")

    # Define Range Query Bounds (e.g., a 10% slice of the domain)
    lower_bound = 10_000_000
    upper_bound = 15_000_000
    print(f"\nExecuting Range Query: [{lower_bound:,} , {upper_bound:,}]")

    # --- Benchmark C++ Range Search (Bucket Pruning) ---
    # Warm-up run
    _ = engine.range_search(lower_bound, upper_bound)
    
    start = time.perf_counter()
    iterations = 50
    for _ in range(iterations):
        cpp_results = engine.range_search(lower_bound, upper_bound)
    cpp_duration = (time.perf_counter() - start) / iterations
    print(f"C++ Modular Engine Range Search: {cpp_duration * 1000:.4f} ms per query")

    # --- Benchmark C++ Range Search (Bucket Pruning) unordered ---
    # Warm-up run
    _ = engine.range_search_unordered(lower_bound, upper_bound)
    
    start = time.perf_counter()
    iterations = 50
    for _ in range(iterations):
        cpp_results_unordered = engine.range_search_unordered(lower_bound, upper_bound)

    cpp_duration_unordered = (time.perf_counter() - start) / iterations
    print(f"C++ Modular Engine Range Search (Unordered): {cpp_duration_unordered * 1000:.4f} ms per query")

    # --- Benchmark Python List Scan (Brute-Force Filter) ---
    # Warm-up run
    _ = [x for x in py_list if lower_bound <= x <= upper_bound]

    start = time.perf_counter()
    for _ in range(iterations):
        py_results = [x for x in py_list if lower_bound <= x <= upper_bound]
    py_duration = (time.perf_counter() - start) / iterations
    print(f"Standard Python List Scan:       {py_duration * 1000:.4f} ms per query")

    # --- Results Summary ---
    speedup = py_duration / cpp_duration if cpp_duration > 0 else 0
    speedup_unordered = py_duration / cpp_duration_unordered if cpp_duration_unordered > 0 else 0
    print(f"\n--- Performance Summary ---")
    print(f"Matched records found: {len(cpp_results):,}")
    print(f"Matched records found (Unordered): {len(cpp_results_unordered):,}")
    print(f"Speedup Factor: **{speedup:.2f}x faster** than Python list scan")
    print(f"Speedup Factor (Unordered): **{speedup_unordered:.2f}x faster** than Python list scan")

if __name__ == "__main__":
    run_benchmark()
