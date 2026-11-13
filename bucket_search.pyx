# distutils: language = c++
# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# cython: extra_compile_args=["-O3", "-march=native", "-std=c++11"]

from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector
from libcpp.algorithm cimport sort as cpp_sort
from libc.math cimport log10


cdef long long power_of_10(int n) nogil:
    """Fast integer power of 10 for exact tier boundary calculations."""
    cdef long long p = 1
    cdef int i
    for i in range(n):
        p *= 10
    return p


cdef class StreamingModularEngine:
    # d_sort[factor][q] = vector of remainders
    cdef unordered_map[long long, unordered_map[long long, vector[long long]]] d_sort
    
    # d_search[factor][q][remainder] = boolean existence flag
    cdef unordered_map[long long, unordered_map[long long, unordered_map[long long, bint]]] d_search

    cpdef void insert(self, long long number):
        """Streaming insert with O(1) amortized hash routing."""
        cdef long long abs_val = number if number >= 0 else -number
        cdef int log_val = <int>(log10(<double>abs_val + 1.0)) if abs_val > 0 else 0
        cdef long long factor = 1 << (log_val + 2)
        
        cdef long long q = number // factor
        cdef long long remainder = number % factor
        
        if not self.d_search[factor][q][remainder]:
            self.d_search[factor][q][remainder] = True
            self.d_sort[factor][q].push_back(remainder)

    cpdef bint search(self, long long number):
        """Blazing fast O(1) point lookup across streaming data."""
        cdef long long abs_val = number if number >= 0 else -number
        cdef int log_val = <int>(log10(<double>abs_val + 1.0)) if abs_val > 0 else 0
        cdef long long factor = 1 << (log_val + 2)
        
        cdef long long q = number // factor
        cdef long long remainder = number % factor
        
        if self.d_search.find(factor) != self.d_search.end():
            if self.d_search[factor].find(q) != self.d_search[factor].end():
                return self.d_search[factor][q].find(remainder) != self.d_search[factor][q].end()
        
        return False

    cpdef vector[long long] get_all_sorted(self):
        """Reconstructs the globally sorted sequence using bucket traversal and C++ sort."""
        cdef vector[long long] result
        cdef vector[long long] factors
        cdef vector[long long] qs
        cdef vector[long long] remainders
        
        # 1. Collect and sort factor keys
        for it in self.d_sort:
            factors.push_back(it.first)
        cpp_sort(factors.begin(), factors.end())
        
        cdef long long factor, q, rem
        for i in range(factors.size()):
            factor = factors[i]
            qs.clear()
            for q_it in self.d_sort[factor]:
                qs.push_back(q_it.first)
            cpp_sort(qs.begin(), qs.end())
            
            # 2. Iterate through quotients and sort local remainder vectors
            for j in range(qs.size()):
                q = qs[j]
                remainders = self.d_sort[factor][q]
                cpp_sort(remainders.begin(), remainders.end())
                
                for k in range(remainders.size()):
                    rem = remainders[k]
                    result.push_back(factor * q + rem)
                    
        return result

    cpdef vector[long long] range_search(self, long long lower, long long upper):
        """
        Query-driven range search using exact mathematical factor and quotient bounding.
        Bypasses out-of-bound factors and quotients entirely with zero redundant sorting.
        """
        cdef vector[long long] result
        if lower > upper or lower < 0:
            return result

        # 1. Determine log magnitudes (digit lengths - 1) for lower and upper bounds
        cdef int log_low = <int>(log10(<double>lower)) if lower > 0 else 0
        cdef int log_high = <int>(log10(<double>upper)) if upper > 0 else 0
        
        cdef int f_min_exp = log_low + 2
        cdef int f_max_exp = log_high + 2
        
        cdef int f
        cdef long long factor
        cdef long long tier_min, tier_max
        cdef long long sub_lower, sub_upper
        cdef long long q_start, q_end
        cdef long long q, rem, val
        
        # 2. Iterate strictly through relevant factor magnitude tiers using powers of 2
        for f in range(f_min_exp, f_max_exp + 1):
            factor = 1LL << f
            
            # Exact decimal tier boundaries for this log magnitude
            # e.g., for log_val = 1 (2-digit numbers: 10 to 99)
            tier_min = power_of_10(f - 2)
            tier_max = power_of_10(f - 1) - 1
            if f == 2: # Edge case for single digits (0 to 9)
                tier_min = 0
                tier_max = 9
            
            # Intersect the global query window [lower, upper] with this tier's bounds
            sub_lower = lower if lower > tier_min else tier_min
            sub_upper = upper if upper < tier_max else tier_max
            
            if sub_lower > sub_upper:
                continue # This factor tier does not overlap with the query range
                
            # 3. Mathematically derive the exact quotient (q) range
            q_start = sub_lower // factor
            q_end = sub_upper // factor
            
            # 4. Probe only the buckets that mathematically exist and intersect
            for q in range(q_start, q_end + 1):
                # Check if factor and q actually exist in our hash map storage
                if self.d_sort.find(factor) != self.d_sort.end():
                    if self.d_sort[factor].find(q) != self.d_sort[factor].end():
                        
                        # Extract remainders for this precise bucket
                        remainders = self.d_sort[factor][q]
                        for k in range(remainders.size()):
                            rem = remainders[k]
                            val = factor * q + rem
                            
                            # Final precise filter check
                            if lower <= val <= upper:
                                result.push_back(val)
                                
        # Optional: Sort final matched results if chronological/sorted return is required
        cpp_sort(result.begin(), result.end())
        return result

    cpdef vector[long long] range_search_unordered(self, long long lower, long long upper):
        """
        Query-driven range search that omits final sorting 
        for maximum raw retrieval throughput.
        """
        cdef vector[long long] result
        if lower > upper or lower < 0:
            return result

        cdef int log_low = <int>(log10(<double>lower)) if lower > 0 else 0
        cdef int log_high = <int>(log10(<double>upper)) if upper > 0 else 0
        
        cdef int f_min_exp = log_low + 2
        cdef int f_max_exp = log_high + 2
        
        cdef int f
        cdef long long factor
        cdef long long tier_min, tier_max
        cdef long long sub_lower, sub_upper
        cdef long long q_start, q_end
        cdef long long q, rem, val
        
        for f in range(f_min_exp, f_max_exp + 1):
            factor = 1LL << f
            
            tier_min = power_of_10(f - 2)
            tier_max = power_of_10(f - 1) - 1
            if f == 2:
                tier_min = 0
                tier_max = 9
            
            sub_lower = lower if lower > tier_min else tier_min
            sub_upper = upper if upper < tier_max else tier_max
            
            if sub_lower > sub_upper:
                continue
                
            q_start = sub_lower // factor
            q_end = sub_upper // factor
            
            for q in range(q_start, q_end + 1):
                if self.d_sort.find(factor) != self.d_sort.end():
                    if self.d_sort[factor].find(q) != self.d_sort[factor].end():
                        remainders = self.d_sort[factor][q]
                        for k in range(remainders.size()):
                            rem = remainders[k]
                            val = factor * q + rem
                            if lower <= val <= upper:
                                result.push_back(val)
                                
        # Intentionally omitted cpp_sort(...) for maximum raw speed
        return result
