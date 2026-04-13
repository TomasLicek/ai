---
name: explain-code
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
argument-hint: <file or code to explain>
description: Explain code for someone learning — teach how it works conceptually. No jargon, honest about complexity. Logic, patterns, design decisions.
---

# Explain Code

Explain this code to someone who is competent but learning. Assume intelligence, not knowledge.

## Approach
1. **What it does** - One sentence. The "elevator pitch."
2. **How it works** - Walk through the logic step by step. Use simple language.
3. **Why it's written this way** - Design decisions, patterns used, tradeoffs made.
4. **The tricky parts** - What's non-obvious? What would trip someone up?
5. **Key concepts** - Any language features, patterns, or domain concepts someone should look up to understand this better.

## Rules
- No jargon without explanation
- If something is weird or smells bad, say so - don't pretend it's normal
- Use analogies when they help
- Be honest about what's clever vs what's unnecessarily complicated

---

Explain $ARGUMENTS
