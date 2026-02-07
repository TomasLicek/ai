---
name: simplify
disable-model-invocation: true
argument-hint: <file or code to simplify>
description: Find what can be deleted, inlined, or made boring
---

# Simplify

This code works but feels overcomplicated. Find what can go.

## Principles
- **The best code is no code.** Can this be deleted entirely?
- **The second best is obvious code.** Can this be rewritten to be boring?
- **Abstractions must earn their place.** Is this indirection necessary or just "clean code" theater?
- **Fewer concepts = fewer bugs.** Every pattern, helper, or layer is cognitive load.

## Look for
1. **Dead code** - Unused functions, unreachable branches, legacy compatibility shims
2. **Premature abstraction** - Helpers used once. Factories creating one type. Interfaces with one implementation.
3. **Overengineering** - Config for things that never change. Plugins with one plugin. Extensibility for extensions that never came.
4. **Indirection without benefit** - Wrapper classes that just delegate. Services that just call other services.
5. **Defensive code against impossible cases** - Null checks for things that can't be null. Error handling for errors that can't happen.

## Output
- List what can be removed or inlined
- Show the simpler version when the change is non-obvious
- Be honest if it's already as simple as it should be

---

Simplify $ARGUMENTS
