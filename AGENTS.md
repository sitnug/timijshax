# timijshax project instructions

## Maintain this file

When a mistake or regression is confirmed, record its cause, the prevention rule, and the check that would have caught it here. Update the record as part of the fix. Do not claim a bug is fixed based only on compilation or a design preview; reproduce the reported failure and test the corrected behavior. State explicitly when Roblox/executor verification remains outstanding.

## Confirmed regressions and prevention

### UI theme property overrides (2026-09-24)

The redesigned header exposed a bug in `FillInstance`: a previously registered theme property took an `elseif` branch that cleared its binding and skipped resolving its replacement. Roblox received the literal string `"BackgroundColor"` in `TextColor3`, causing `Color3 expected, got string` and preventing startup.

- Always resolve theme tokens and callbacks after clearing an old binding. Never let a cleanup branch bypass value conversion.
- Keep the fix consistent in `DEPENDENCIES/Library.lua` and `DEPENDENCIES/LibraryClassic.lua`.
- Test the actual factory extracted from each source with typed property setters. Cover default-to-token overrides, token-to-token replacements, literal colors, callback values, and subsequent theme refresh.
- Run `python3 TESTS/theme_registry.py /path/to/luau` for theme, UI factory, or template changes. Also compile changed Luau files.
- HTML previews validate appearance only. They cannot establish that Roblox property assignments or executor APIs work.

### Silent startup errors and stale releases (2026-09-24)

The loader discarded `pcall` errors and retained older official source URLs between executions, obscuring failures and making updates unreliable.

- Preserve visible download, compilation, unsupported-game, and startup diagnostics.
- Advance `loader.lua`'s release pin only after committing the runtime/dependency fixes. Verify the exact published commit URLs, not only a potentially stale raw `main` URL.
- Refresh stale official pins while preserving deliberate custom-source behavior. Verify recovery mode against the same release as the primary UI.

### Git privacy (2026-09-24)

Commits were initially published with a personal local Git identity, and inherited automatic collectors were left enabled.

- Use repository-local `sitnug` / `115773975+sitnug@users.noreply.github.com` for commits. Check author and committer metadata before publishing.
- Keep automatic upstream analytics, Stella collection, and chat/error reporting removed. Do not reintroduce third-party executable icon loaders.
- Never commit runtime logs, account data, credentials, caches, configs, or local support requests. Preserve the explicit source allowlist.
- A rewritten branch does not guarantee cached commits disappeared. Verify and report residual exposure; do not claim complete removal without evidence.

### Shell variable names (2026-09-24)

In zsh, `path` is tied to `PATH`; using it as a loop variable broke command lookup in one shell call. Use task-specific variable names and never repurpose `path`, `PATH`, `HOME`, or `CODEX_HOME`.

### Recovery after repeated failed startup (2026-09-24)

The user reported no startup output after multiple loader/UI changes, despite the first version working. The exact additional executor-side failure has not been reproduced. Runtime was returned to the first renamed version, with the established color fix, bundled icons, and privacy removals retained; newer runtime features are temporarily inactive.

- Stop layering new UI and loader behavior onto an unverified failure. Recover from the user's last confirmed working baseline first.
- The first executable loader statement must report locally before any `game:IsLoaded()` wait, HTTP fetch, asset registration, or audio task. Never describe missing logs as a confirmed diagnosis without evidence.
- Keep the recovery loader simple and clear stale source pins. This recovery release intentionally uses the original main-branch loading approach; verify both published commit content and freshness of fetched dependencies.
- Do not re-enable suspended features or redesigns until the user confirms baseline startup. Recover historical code without resurrecting automatic telemetry or private Git metadata.

### Confirmed recovery baseline and feature restoration (2026-09-24)

The user confirmed recovery revision `c8aec531c20e88e857abf578edaeb9381d135ffe` starts successfully. They then requested the features back and noted earlier execution may have been incorrect. Do not treat the unexplained silent failure as a proven code defect beyond the separately reproduced theme error.

- Restore additions onto this confirmed layout without changing its window construction, navigation, or shared UI factory.
- Voice playback must remain asynchronous and optional; a missing audio capability must report locally without blocking startup.
- Ingredient filters, local spawn memory, and the read-only Explorer can be restored independently of the unconfirmed full redesign. Maintain privacy removals.
- Run the theme-property, ingredient filter, and spawn-memory checks when restoring those paths; distinguish local tests from live user confirmation.

### Redesigned UI explicitly restored (2026-09-24)

After confirming the recovery baseline and restored features, the user asked for the redesigned UI too. Restore only its window/tab configuration and fixed shared library/theme; preserve the working loader, audio, ingredient filtering, spawn memory, and privacy changes. The UI factory must retain the reproduced-and-tested theme override fix. Do not describe the redesigned UI as in-game verified until the user confirms it.

### Search visibility and reusable updates (2026-09-24)

Search clearing previously restored controls regardless of explicit visibility and retained empty group shells. Preserve each control's `Visible` state, hide empty outer holders, and treat user search punctuation literally. Run `TESTS/search.py` with Luau for search changes, alongside the theme factory checks.

A commit-pinned snippet cannot receive future releases. The reusable bootstrap resolves main to an exact revision on every execution and replaces old source pins. Keep loader and dependencies on that single revision; report update-check failures explicitly. Never place repository write credentials in distributed scripts. Local spawn memory remains private and automatic; shared uploads were declined.

### Teleport analysis completeness (2026-09-24)

An explanation of teleport behavior covered inn resets but missed the existing route bot's `Gate` helper. Search all movement and route helpers before describing capabilities. Distinguish Gate casting, inn respawn, server teleport, and arbitrary-coordinate movement. Area labels are nearest-marker estimates, not verified region boundaries or Gate names.
