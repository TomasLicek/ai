---
name: root-cause
disable-model-invocation: true
argument-hint: <problem or symptom to investigate>
description: Five whys until bedrock - symptoms are not causes
---

# Root Cause Analysis

Don't tell me the symptom. Dig until you find the actual cause.

## The Five Whys (but actually do them)
Keep asking "why" until you hit bedrock. Surface answers are not acceptable.

Example:
- "The page is slow" → Why?
- "The API takes 3 seconds" → Why?
- "It's doing N+1 queries" → Why?
- "The ORM is lazy-loading associations" → Why wasn't this caught?
- "No query logging in dev, no performance tests" → **Root cause: missing observability**

## Rules
1. **Symptoms are not causes.** "It throws an error" is not a root cause.
2. **Proximate causes are not root causes.** "This variable is null" - why is it null?
3. **Go deeper than the code.** Sometimes the root cause is process, communication, or missing tests.
4. **Question the premises.** Maybe the feature shouldn't exist. Maybe the architecture is wrong.
5. **Find the system failure.** Why did the system allow this bug to exist? What check was missing?

## Output
- Trace the causal chain from symptom to root
- Identify the actual root cause (there may be multiple)
- Suggest fixes at the root level, not band-aids at the symptom level

---

Investigate $ARGUMENTS
