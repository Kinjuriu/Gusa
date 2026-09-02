# How we work together on Gusa

Four people, four machines, one repo. This page is the whole process. If something here is wrong for you, say so in the team chat and we change the page, not the habit.

## 1. Who owns what

| Lane | Person | Spec | Folders |
|---|---|---|---|
| A · App and integration | Ian (@Ianodad) | [`docs/WIREFRAMES.md`](docs/WIREFRAMES.md) + [`docs/TEAM-PLAN.md`](docs/TEAM-PLAN.md) §4 | `lib/app/ lib/features/ lib/ports/ lib/storage/` |
| T · Tactile | Stephane (@Kinjuriu) | [`docs/specs/SPEC-T-tactile.md`](docs/specs/SPEC-T-tactile.md) | `lib/core/braille/ lib/core/haptics/ lib/core/practice/` |
| I · Input | Ian (@Ianodad) | [`docs/specs/SPEC-I-input.md`](docs/specs/SPEC-I-input.md) | `lib/core/braille_keyboard/ lib/core/gestures/ lib/core/quick_reply/` |
| V · Voice + Words | Kevin (@future-centaur) | [`docs/specs/SPEC-V-voice.md`](docs/specs/SPEC-V-voice.md) | `lib/services/ proxy/` |

Three people, four lanes: Ian carries App and Input. Ian reviews every PR except his own; Stephane reviews Ian's App and Input PRs. Ian is the final approver on everything else. You never merge your own PR. You never edit another lane's folders; if you need something from them, open an issue tagged with their lane.

## 2. Your first hour

1. Do [`docs/SETUP.md`](docs/SETUP.md). Plug in a phone. Post the `doctor.sh` output and a screenshot of the app running on your phone in the **Week 0** issue.
2. Read, in this order: `docs/TEAM-PLAN.md` §0–4, `docs/DECISIONS.md`, `docs/WIREFRAMES.md`, then your spec.
3. `git fetch && git checkout <your first branch>` (the branch name is at the top of your spec). It was created from `develop` for you.
4. Reply in the team chat with one line: anything in your spec you disagree with or do not understand. Silence means you agree with all of it.

## 3. The loop for every task

```
pick task ID  →  branch  →  small commits  →  Draft PR early  →  CI green  →  ask review  →  fix  →  squash-merge  →  delete branch  →  next task
```

- **Branch:** `feat/<lane>/<ID>-<slug>` from `develop`, e.g. `feat/t/T1.2-haptic-engine`. One task ID per branch. Your first branch already exists.
- **Commits:** start the message with the task ID: `T1.1: capital indicator encodes as dot 6`. Small commits, pushed daily, so nothing lives only on your laptop.
- **Draft PR on day one** of a task, even with one commit. It shows everyone what you are doing and lets CI run. Mark it "Ready for review" when the spec's *verify by* is met.
- **PR title:** `T1.1 BrailleEngine grade 1` (ID, then what). Fill every field of the template; a PR with an empty "How verified" is sent back without review.
- **Review:** request Ian. If the PR touches `lib/ports/`, also request the other lane it affects. Reviews come within 24 hours; if not, say so in the chat.
- **Merge:** the reviewer squash-merges. The branch is deleted. You pull `develop` and start the next ID.

Rebase on `develop` before you open the PR and before you mark it ready. Never force-push `develop` or `main`. Never commit `.env.json`, keys, audio, videos, or anything a user said.

## 4. Reviews: what the reviewer checks

1. The spec's *verify by* line is met and shown (test output, phone video, numbers).
2. Tests exist for new code and CI is green.
3. Only your lane's folders changed, or it is a contract PR with both approvals.
4. Nothing from "what never goes in the repo" is in the diff.
5. Any divergence from the spec is written in the PR, with the reason.

The reviewer either approves or asks for changes with a concrete request. "Looks wrong" is not a review comment; "chord window of 250 ms mis-fires on my Tecno, try 350" is.

## 5. Contracts: the one place we can break each other

`lib/ports/` is shared. To change a port:

1. Branch `contract/<slug>`.
2. Change the port, its fake, its fixtures, and every consumer **in the same PR**.
3. Label `contract`. Request Ian plus every lane that implements or consumes it.
4. It merges only with all approvals. Contract PRs are reviewed the same day.

Until it merges, build against the fake. Never copy a port into your own folder.

## 6. When you are blocked or the spec is wrong

1. Write what you tried and what happened in the task's issue. Screenshots, logs, phone model.
2. Post the issue link in the team chat with one line.
3. If the spec itself is wrong, propose the change in your PR description under "Diverged from spec" and keep going on the parts that are not blocked. Ian answers within a day.
4. One escalation per task. Once Ian answers, that is the spec.

Never work around a problem silently. A quiet workaround becomes another lane's bug.

## 7. Rhythm

| When | What | How long |
|---|---|---|
| Every morning | One message in the chat: *yesterday · today · blocked* | 3 lines |
| Monday | Planning call: each person names this week's task IDs and any blocker | 30 min |
| Friday | Demo call: Ian installs the `develop` build on every phone, one person demos the week's slice | 30 min |
| Stage exits | Live demo against the exit criteria in `docs/TEAM-PLAN.md` §4; results into `docs/TEST-RESULTS.md` | in the Friday call |

Missed the call? Post your three lines anyway. The chat is the record; calls are for decisions.

## 8. Phones and evidence

Everything tactile is verified on a phone, never on the emulator. Record short videos with the large-text mirror visible. Attach them to the PR (drag into the description); do not commit them. Name the phone model in every PR. Two different makers across the team is the minimum; say which you have in the Week 0 issue.

## 9. Decisions

If you need a decision that is not in `docs/DECISIONS.md`, open a PR that adds a row with your proposed default and "OPEN". Ian decides and marks it. Decisions are not made in chat.

## 10. Style

- `dart format` and `flutter analyze` clean before every push (CI enforces).
- Plugin imports live only in the adapter files your spec names. Everything else imports the port.
- Constants and thresholds in one file per lane, not scattered.
- No TODOs without an issue number.

## 11. What never goes in the repo

API keys, `.env.json`, audio, videos, screenshots, anything a real user said or typed, raw logs from a phone. If you are unsure, it does not go in.
