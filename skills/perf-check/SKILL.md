---
name: perf-check
disable-model-invocation: true
argument-hint: <code, function, or file to check>
description: Back-of-envelope performance check — is this code unreasonably slow?
---

# Performance Ballpark Check

Quick sanity check: is this code in the right ballpark, or is it leaving 10-100x on the table?

## Conservative Node.js Baselines (V8 JIT warm, any modern machine)

These are intentionally low. If code is slower than these, it's definitely a problem.

| Operation | ~ops/sec | Order of magnitude |
|---|---|---|
| Simple arithmetic | 750M | 10^8-9 |
| Property access | 200M | 10^8 |
| Function call | 200M | 10^8 |
| Object allocation | 200M | 10^8 |
| Array .map() per element | 100M | 10^8 |
| String concat | 50M | 10^7 |

Benchmarked on M2 Mac, Node v25. x86 machines may be 30-50% slower.

**Python (CPython):** divide Node numbers by ~10-20x.

## The Method

1. **Estimate operations**: How many items? How many ops per item? (loops, function calls, allocations)
2. **Calculate theoretical time**: `items × ops_per_item / baseline_ops_sec`
3. **Compare to actual time**: If actual is 10x+ worse than theoretical, dig in.
4. **Write a baseline**: Simplest possible implementation in the SAME language. 1-3 lines. Measure it. The gap between baseline and their code is the waste.

## Key Principle

**Don't compare to hardware limits — compare to the runtime's limits.** The interpreter tax is a given. What you're hunting is the bad-code tax on top of it.

## Common Waste Patterns (where the 10-100x usually hides)

- **Allocations in hot loops**: `.map().filter().reduce()` chains creating 3 intermediate arrays
- **O(n²) hiding as O(n)**: nested `.find()` or `.includes()` inside a loop
- **Repeated work**: parsing the same string, computing the same value, re-creating objects
- **Wrong data structure**: linear search where a Set/Map lookup would be O(1)

## Output Format

1. **Quick estimate**: "N items × M ops/item ÷ baseline = expected time"
2. **Actual vs expected**: show the gap
3. **Write a baseline**: minimal implementation, measure it
4. **Diagnosis**: where's the waste? Show what better looks like.

---

Analyze $ARGUMENTS

