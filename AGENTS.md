# Repository Guidelines

## Project Structure

`harmony/` contains the production HarmonyOS NEXT app.

ArkTS source lives in `harmony/entry/src/main/ets/`:

```text
app/          App composition, routes, theme
components/   Shared UI
features/     Screens and feature-local UI
domain/       Business models
data/         Catalog, database, repositories
services/     Aggregation, trends, recommendations
model/        Remaining compatibility models
```

Catalog JSON and exercise media are under `harmony/entry/src/main/resources/`. Maintenance scripts are in `harmony/tools/`.

## Source of Truth

Before coding, read in this order:

1. `docs/PRODUCT_SPEC.md`
2. `docs/DATABASE_DESIGN.md`
3. `docs/APP_STRUCTURE.md`
4. `docs/ROADMAP.md`
5. Current source code in `harmony/`

If documents conflict with current source about an implementation detail, verify the source and update the corresponding current-state document as part of the change.

Do not restore behavior from old A/B beginner-product documents or historical Phase plans.

Historical implementation information belongs in Git history, not new `PHASE*_DEVELOPMENT_RECORD.md` files.

## Current Product Boundary

The current product is a goal-driven fat-loss and strength-training execution assistant.

The supported core scenario is:

```text
fat loss
3 required gym strength sessions per week
optional 4th session
upper-body priority
body / nutrition / steps / strength tracking
```

Before adding new product scope, finish P0/P1 items in `docs/ROADMAP.md`.

Do not add AI Coach, cloud sync, community, marketplace, large food databases, or complex training analytics unless the roadmap has explicitly moved them into active scope.

## Architecture Rules

Preferred dependency direction:

```text
Page / AppRoot
→ Service
→ Repository
→ ArkData
```

Rules:

- Keep SQL out of UI code.
- Keep historical facts in repositories and database records.
- Keep aggregation, trends, recommendation and Today Plan rules in services.
- Do not infer historical completion from UI state or Program cursor values.
- `next_required_workout_index` is a cursor, not a weekly-completion truth source.
- Weekly completion must be derived from completed `workout_session` rows.
- Database weights are stored in kg. UI unit conversion must happen at a shared boundary.
- Program exercise IDs are stable catalog IDs; never join by Chinese exercise name.
- Preserve workout/exercise/set snapshots so later catalog or Program edits do not rewrite history.

`AppRoot` should coordinate lifecycle, routing and feature wiring. Avoid adding new calculation/aggregation logic there when a Service is appropriate.

## Database Rules

Current database version is documented in `docs/DATABASE_DESIGN.md`.

For any schema change:

1. Increase the database version.
2. Add an explicit sequential migration.
3. Preserve old workout/body/nutrition history.
4. Keep migrations idempotent where practical.
5. Never solve migration failures by deleting the user database.
6. Verify Fresh install and relevant old-version upgrade paths.

Do not use repair SQL as a substitute for a formal migration when introducing a new schema version.

## Build and Test

From `harmony/`, build the signed debug HAP:

```bash
DEVECO_SDK_HOME="$PWD/.sdk" /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

Artifact:

```text
harmony/entry/build/default/outputs/default/entry-default-signed.hap
```

For affected flows, verify on an emulator or Mate 60 Pro.

Database/workout changes must consider:

```text
Fresh install
V1 → latest
V2 → latest
restart
active-workout recovery
rest recovery
finish idempotency
history integrity
```

Business-rule changes should add automated or repeatable tests when possible, especially Today Plan, Program week status, trends, weekly statistics, progression, units and migrations.

## UI and Interaction Rules

Current top-level navigation is:

```text
今日 / 训练 / 数据 / 我的
```

Workout execution is immersive and does not show bottom navigation.

Prefer Sheets for short contextual actions such as body quick entry, workout exit confirmation and exercise tips instead of adding unnecessary routes.

Use shared theme tokens and shared navigation components. Keep interactions low-friction; daily logging should not require navigating through Settings when a direct Sheet or quick action is sufficient.

## Style and Naming

- Two-space indentation.
- Semicolons.
- Explicit ArkTS types.
- Small feature-local components.
- Classes/components: `PascalCase`.
- Methods/variables: `camelCase`.
- Constants: `UPPER_SNAKE_CASE`.
- Preserve theme tokens.
- Prefer focused, reviewable changes over large rewrites.

## Commits and Pull Requests

Use short imperative conventional prefixes such as:

```text
feat:
fix:
refactor:
docs:
test:
```

PRs should describe user-visible behavior, affected modules, verification commands and screenshots for meaningful UI changes.

Do not commit generated build output, credentials or signing keys.

## Documentation Policy

Keep only current, actionable documentation on the main branch.

Do not create:

```text
PHASE1_DEVELOPMENT_RECORD.md
PHASE2_DEVELOPMENT_RECORD.md
...
REMEDIATION_*_RECORD.md
```

Use commits/PRs for implementation history.

When a current-state document becomes wrong, update or replace it instead of adding another competing version.

## Security and Distribution

Keep signing configuration local.

Review upstream exercise catalog/media licensing and retain required attribution before distribution.

## Exercise Catalog Quality Gate

Exercise catalog changes require, in order:

```text
node harmony/tools/generate_exercise_translation_candidates.mjs
node harmony/tools/report_exercise_unknown_tokens.mjs
node harmony/tools/report_exercise_candidate_conflicts.mjs
node harmony/tools/generate_exercise_review_queue.mjs
node harmony/tools/promote_auto_reviewed_exercises.mjs --dry-run
node harmony/tools/promote_auto_reviewed_exercises.mjs
node harmony/tools/promote_exercise_localization_reviews.mjs
node harmony/tools/sync_exercise_catalog.mjs
node harmony/tools/validate_exercise_catalog.mjs
node harmony/tools/report_exercise_localization.mjs
HarmonyOS debug build
```

The full pipeline must cover every upstream exercise. Generated records must include a candidate (or
an explicit failure), metadataCandidate, translation confidence/method, quality grade and issues.
`auto_reviewed`, `needs_review` and `needs_manual` are generated quality grades; only the first may
be auto-promoted, and auto-promote writes `reviewed`, never `approved`. Machine-generated
localization is never automatically marked `approved`. `aliasesZh` must contain only same-exercise
synonyms, never biomechanically distinct variants. Ambiguous exercise names must not be resolved by
returning the first match; callers must handle the resolver's `ambiguous` result. Candidate
generation must never overwrite `harmony/data/exercise_localization_reviews.zh-CN.json`.
All 1324 actions remain processed even when `libraryVisible` is false; visibility and recommendation
are separate metadata gates.
Recommendation, content review and library visibility are maintained in
`harmony/data/exercise_metadata_overrides.json`, not inferred from a hard-coded ID set.
