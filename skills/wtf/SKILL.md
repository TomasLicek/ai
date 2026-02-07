---
name: wtf
disable-model-invocation: true
argument-hint: <file or code to trace>
description: Step-by-step execution trace - what is this actually doing
---

# WTF Is This Code Doing

Explain what this code is actually doing. Step by step. No jargon. No handwaving.

## Approach
Trace the execution path like you're a debugger with a hangover:

1. **Entry point** - Where does this start? What triggers it?
2. **Step by step** - What happens first? Then what? Be painfully literal.
3. **Data flow** - What goes in? What comes out? What gets mutated along the way?
4. **Side effects** - What does this touch? Database? Files? External APIs? Global state?
5. **The weird parts** - What's confusing? What looks wrong? What made you go "wtf" in the first place?

## Rules
- Assume I've never seen this codebase before
- No "it's just standard X pattern" - explain what it actually does
- If the code is confusing, say so. Don't pretend it makes sense.
- If there's magic (metaprogramming, reflection, codegen), expose the trick
- Use plain language. "It loops through users and checks each one" not "It iterates over the user collection applying the predicate"

---

Explain WTF $ARGUMENTS
