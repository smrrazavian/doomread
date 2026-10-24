# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

## Extra labels

Use these alongside the triage roles to say where an issue lives. Create them on first use (`gh label create <name>`).

| Label     | Meaning                                                       |
| --------- | ------------------------------------------------------------- |
| `android` | Android app, including native Kotlin edges                    |
| `linux`   | Linux desktop app and browser extension                       |
| `ios`     | iOS (later phase)                                             |
| `server`  | Sync/accounts server, docker compose, ntfy                    |
| `persian` | Persian locale: RTL, copy, Solar Hijri calendar, digits, fonts |
| `design`  | Visual design, mockups, copy and tone                         |
| `P1`      | Priority: do next                                             |
| `P2`      | Priority: soon                                                |
| `P3`      | Priority: later / nice to have                                |
