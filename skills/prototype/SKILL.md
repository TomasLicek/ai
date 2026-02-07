---
name: prototype
disable-model-invocation: true
argument-hint: <idea to prototype>
description: Build the dumbest version that works, then stop
---

# Prototype

Build the stupidest thing that proves the idea. Then stop.

## Rules

- **No abstractions.** Hardcode everything. One file if possible.
- **No error handling.** If it crashes, we'll see why.
- **No tests.** This is the test.
- **No config.** Constants at the top of the file.
- **No "while we're at it."** Prove one thing. One.
- **Time limit mindset.** If this takes more than 30 minutes of coding, you're overbuilding.

## Flow

1. Clarify: what's the one question this prototype answers? "Can we...?" "Does this work?" "Is this fast enough?"
2. Build the minimal thing that answers it.
3. Run it. Does it answer the question?
4. Report: yes/no/kinda, and what we learned.
5. **Stop.** Don't clean up. Don't refactor. Don't "just add one more thing."

## When it's done

The prototype answered the question. Now Tom decides:
- Kill it — the idea doesn't hold up
- Build it properly — start fresh with what we learned (this is NOT the prototype)
- Keep exploring — new questions emerged

The prototype is never the foundation. It's the napkin sketch.

---

Prototype: $ARGUMENTS
