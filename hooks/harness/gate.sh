#!/usr/bin/env bash
# Hook gating helper. Source, then call `hook_enabled NAME`.
# Project opts in by creating `.claude/hooks/<NAME>.enabled` in its root.

hook_enabled() {
  [[ -f ".claude/hooks/${1}.enabled" ]]
}
