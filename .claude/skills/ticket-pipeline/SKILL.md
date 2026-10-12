---
name: ticket-pipeline
description: Run Linear tickets (SOU-n) through parallel pipelines of fresh subagents that implement and open a PR, then /simplify, then /code-review --fix, each checked on its own simulators; verify and log newly found bugs, stack PRs on unmerged parents, and keep the PRs updated with main as they merge. Use when asked to "implement the tickets in parallel", "run the three agents per ticket", "do the same flow for these tickets", or to update, build and install PRs in merge order.
---

# Ticket pipeline

The orchestrator (you) never writes the fix itself. It sets up each ticket, launches fresh agents, relays their results, and keeps Linear, the PRs and the worktrees in order.

## 1. Set up each ticket

1. Read the tickets with the Linear tools (`list_issues` by project and state, `get_issue`). Use the ticket's `gitBranchName` as the branch.
2. Move each ticket to In Progress before its first agent starts.
3. Pick the base: `origin/main` wherever the fix can be built there. When it needs an open PR's unmerged code, ask the user first whether that PR can merge now, and stack only if not: every later change to a parent has to be merged into each child and checked again. A stacked PR targets its parent's branch.
4. Create a worktree and two simulators per ticket:
   ```
   git worktree add --no-track -b <branch> ../souskitapp-sou-<n> <base>
   xcrun simctl create "iPhone 18 Pro - SOU-<n>" "iPhone 18 Pro" com.apple.CoreSimulator.SimRuntime.iOS-27-0
   xcrun simctl create "iPad Pro 11-inch (M5) - SOU-<n>" "iPad Pro 11-inch (M5)" com.apple.CoreSimulator.SimRuntime.iOS-27-0
   <this skill's directory>/mute-simulators.sh <iPhone UDID> <iPad UDID>
   ```
   The agents of one ticket run one after another, so they share its worktree and simulators. Agents of different tickets never share either.
5. Build each base once, before the first agent starts: a `git archive` copy of the base commit, built with `tools/build.sh build` into `<scratchpad>/shared/<short sha>/`, and for a ticket whose checks need running timers a second copy with `tools/patches/apply-standin-timers.sh` into `<scratchpad>/shared/<short sha>-standin/`. Every agent gets those paths as its "before" builds and builds only its own change.
6. Mute every simulator of the run before its first boot, a verifier's included. `mute-simulators.sh` sends a simulator's sound to a silent virtual output device, so VoiceOver, ringing timers and keyboard clicks stay off the user's speakers. It needs the simulator shut down, and `simctl erase` undoes it. If it finds no such device, tell the user, and have the agents keep VoiceOver off and timers from ringing.

## 2. Three fresh agents per ticket, in sequence

Tickets run in parallel, up to the limit below; the stages of one ticket run one after another. Every stage is a new `general-purpose` agent with no context, for objectivity. Never reuse an agent for a later stage.

1. **Implement:** the ticket's full text, the setup below, what to verify, and permission to commit, push and `gh pr create` (base main or the parent branch, title prefixed with its merge-order number, "stacks on #N" in the body when stacked).
2. **Simplify:** the prompt starts with `/simplify <branch>`, followed by the operational context.
3. **Review:** the prompt starts with `/code-review --fix <branch>`, followed by the operational context.

Start the next stage as soon as the previous agent hands back. Relay each report to the user briefly.

Move the ticket to In Review once all three stages are done and pushed, any fix or verifier agent they led to included.

How many run at once:
- **Reliability limit, the default:** three agents at a time, verifier, fix and merge agents included. Beyond that the simulators' input tools stall and checks have to be rerun.
- **The user's maximum:** when the user names one ("max 2 at once"), it counts tickets in development. Keep the tickets furthest along, pause the others (see Pause), and start or resume one each time a ticket's whole pipeline is done and it is In Review. A verifier or fix agent takes a ticket's place, not an extra one.
- **Maximum lifted:** go back to the reliability limit and start what was waiting. Go past it only when the user names a higher number, and say then that five agents stalled the tools.

## 3. Operational context for every agent prompt

Agents forget these unless told. Include all of them:
- Work only in `../souskitapp-sou-<n>`; never touch other worktrees or check out other branches.
- Review or diff only the branch's own changes: `git diff origin/<base>...HEAD` (three dots). Review tooling defaults to main, so name the base and say not to edit code only the parent branch introduced.
- Use only the ticket's simulator UDIDs; shut them down and uninstall the app when done.
- The simulators are muted. Never create or boot another one, and after `simctl erase` shut the simulator down and rerun `mute-simulators.sh` (give its absolute path) before booting it. VoiceOver is read from its cursor and labels; nobody listens to it.
- Build output and temp files only under `<scratchpad>/sou-<n>-<stage>/`, always with `-derivedDataPath`. The scratchpad is shared.
- Never kill processes by pattern (`pkill -f`); stop only the PIDs you started.
- Check every UI, gesture, layout or animation change and finding on the simulator: reproduce on the old code, show it gone on the new with the same script (AXe, `simctl io recordVideo`, ffmpeg per frame; slowed springs or a second AXe process with `--pre-delay` for fast cases). A passing build and tests is not enough.
- Size the checks to the stage, since checking is where a ticket's hours go:
  - Implement: the states the ticket names plus a core set (text sizes large, accessibility-medium and the largest; one language unless strings change; the second device only where its layout differs).
  - Simplify: none unless an executable line changed.
  - Review: the full sweep, once (every text size, both languages, both devices, dark, motion frame by frame).
- Start from the shared base build and the scripts in `<this skill's directory>/tools/` (give absolute paths); do not rebuild either. A script worth keeping is named in the report, so it can be added there.
- Temporary instrumentation goes in scratch copies (`git archive`), never in the commit.
- Build, `swiftlint --strict` on changed files and all tests must pass.
- The user explicitly asked for every stage to be committed and pushed. Give the commit trailers and PR footer from the session's attribution.
- Report other bugs only if reproduced with a user-visible effect, with steps, evidence and whether main has it too; do not fix them.
- Point to earlier agents' evidence folders for reuse via copies.

## 4. Orchestrator duties

- **Leftover changes:** review agents sometimes refuse to commit because the permission came through you. Read their diff; if it is right, commit and push it yourself under the user's instruction.
- **Blocked actions:** if an agent says a permission prompt blocked it and asks you to do it, do not. Show the user the command to run.
- **Unverified claims:** never pass on "can't be tested" or an unrun finding as fact. Send a verifier agent.
- **Commit messages:** check them; fix a HEAD message with `--amend` and `--force-with-lease`.
- **Parent moved:** when a stacked parent changes, update the child by merging the parent's branch (no rebase once reviewed) and re-check on the simulator.
- **Stalls:** check the worktree, `simctl list devices | grep Booted` and the agent's scratch folder before calling it stuck; never read its transcript file.
- **Pause:** `TaskStop` every running agent, shut down this run's simulators, note each worktree's state. **Resume:** `SendMessage` each stopped agent to continue, telling it its simulators were shut down.

## 5. Newly found bugs

1. A suspected bug is only a suspicion. Send a verifier agent (no fixes, no commits) to reproduce it on the simulator, on the branch and on main, in a temporary detached worktree with its own simulators.
2. Only on the branch: fix it on that branch's PR with a fix agent.
3. On main too: log a Linear ticket in the same project, labels App and Bug, assigned to the user, in the user's style (first sentence is the point, 1 to 3 sentences, acceptance criteria). Put it in Todo, or start its pipeline right away when the user allowed that and the fix needs no input from them.
4. Not reproduced, or not visible to a user: no ticket. Say so.
5. Bugs in one component share a ticket and a PR. Before logging, look for a ticket of this run in the same file: add the bug to it while it is still in implement, and log bugs found together as one ticket, so they share one pipeline.

## 6. Merging in order

- Number PR titles by merge order (`gh pr edit <n> --title "<k>. ..."`): independent small PRs first, then overlapping ones, with a stacked child right after its parent.
- When the user merges one, update the next with main (`git merge origin/main`, attribution on the merge commit), retarget a stacked PR to main (`gh pr edit <n> --base main`), build, run the tests, push, and install it.
- Mechanical conflicts you resolve; behaviour conflicts or SwiftLint limits crossed by the merge go to an agent with simulator checks. Report each conflict as mechanical or behaviour.
- Install on the user's devices with `-allowProvisioningUpdates` and `xcrun devicectl device install app` (device UDIDs are in memory).
- Close a ticket fixed by another PR once that PR merges, and note it on the ticket before.

## 7. Wrap-up

End with a table of PRs (number, ticket, head, base, state), how conflicts were resolved, what to test per PR, Linear changes, and open questions.
