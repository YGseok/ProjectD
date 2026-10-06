---
name: feedback-push-after-each-iteration
description: "After every autonomous loop iteration that produces a commit in ProjectD, push to origin immediately — don't batch pushes."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 08652cec-13b7-48ef-866d-b76e8abb51e2
  modified: 2026-09-07T01:18:23.941Z
---

Whenever an iteration of ProjectD's Godot dev loop (whether run via `Util/loop/loop.sh` or by directly invoking `claude -p` per iteration, as this session does when the user asks for a bounded number of iterations) produces a git commit, push it to `origin/master` right away — after each individual iteration, not batched at the end of a session or a multi-iteration run.

**Why**: the user explicitly asked for this (2026-09-07) after noticing the Claude Code Desktop panel's ahead/behind indicator (e.g. "+118 -5") reflecting a real unpushed commit that had been sitting local for a while. Cross-PC continuity (see [[project_setting_sync_projectd]]) only works if commits actually make it to the remote promptly — a local-only commit is invisible to any other machine until pushed.

**How to apply**: after confirming an iteration's commit landed (`git log -1`), run `git push` before moving on to the next iteration or ending the turn. If an iteration is killed/times out mid-work and leaves the tree dirty (no commit), there's nothing to push yet — just note the uncommitted state and push once a later iteration actually commits it. No need to run the `Setting/sync-to-repo.ps1` memory-sync step before every single push — that's a separate, coarser action for when Claude memory/settings should also be shared; the loop's own code commits can push directly with plain `git push`.
