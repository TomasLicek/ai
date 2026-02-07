# Ideas and tips

- Ride them all
    - Use CC together with Codex or Gemini. Maybe even cursor cli?
    - You can use the headless option only to combine them. Use Gemini 1M context as advantage, others may review.
    - Vice versa, gemini can "have sub-agents" if you spawn Claude in cli
- CC hook for permission request
    - Route permission requests to Opus via a hook — let it scan for attacks and auto-approve the safe ones (see https://code.claude.com/docs/en/hooks#permissionrequest)
