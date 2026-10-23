# Contributing

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/), adapted to this repo:

```
<type>(<scope>): <summary>

<body>

<footer>
```

- **type**: what kind of change.
  - `feat`: user-visible behaviour
  - `fix`: a bug fix
  - `refactor`: same behaviour, different code
  - `perf`: faster or smaller
  - `test`: tests only
  - `docs`: documentation, ADRs, mockups
  - `build`: dependencies, the dev image, Gradle
  - `ci`: GitHub Actions
  - `chore`: anything else
- **scope** (optional): `app`, `core`, `server`, `tool`, `ci`, `docs`. Use a comma for two (`app,server`). Leave it out for repo-wide changes.
- **summary**:
  - Imperative and lowercase ("add the Road", not "Added the Road."), with no full stop.
  - The whole first line is at most 72 characters.
  - Use the domain words from `CONTEXT.md`: Work, Road, Session, Stretch, Urge, Slip and so on.
- **body**: explain *why* first, then what changed. Wrap at 72. Leave it out when the summary says it all.
- **footer**:
  - `Closes #n` closes a ticket on merge to `main`. `Refs #n` links without closing.
  - `BREAKING CHANGE: …` for anything that breaks stored data or the API.
- **Never** add a `Co-Authored-By` trailer or other AI attribution.

Examples:

```
feat(app): show the current Work on its Road on Tonight

The Road is the user's way to the last page; Tonight now draws it with
Checkpoint ticks and the finish flag, mirrored in Persian.

Closes #2
```

```
fix(server): cap credential bodies at 4 KB before reading
```

`.githooks/commit-msg` checks the first line. Enable it once per clone:

```sh
git config core.hooksPath .githooks
```
