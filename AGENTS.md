# Repository Guidelines

## Project Structure & Module Organization

`harmony/` is the production HarmonyOS NEXT app (ArkTS, ArkUI, ArkData). Keep app composition in `entry/src/main/ets/app`, screens under `features/`, reusable UI in `components/`, business models in `domain/` and `model/`, repositories/database code in `data/`, and bundled catalog/media in `entry/src/main/resources`. `harmony/tools/` contains catalog and media generation scripts. `prototype/` is the browser-based visual prototype; its app-owned UI lives in `src/`. Product requirements, research, and reference screenshots are in `docs/`, `design/`, and `docs/效果图/`. There is currently no dedicated Harmony unit-test tree.

## V2 Product Source of Truth

Before implementing V2 features, read these files in order:

1. `docs/PRODUCT_SPEC.md`
2. `docs/DATABASE_DESIGN.md`
3. `docs/PAGE_STRUCTURE.md`
4. `docs/AGENT_IMPLEMENTATION_PLAN.md`
5. `docs/IMPLEMENTATION_REFERENCE.md`

If requirements conflict, the earlier document wins. `IMPLEMENTATION_REFERENCE.md` documents the existing V1 implementation and compatibility constraints; it is not the V2 product decision source.

The V2 product is goal-driven fat-loss and strength-training execution. Do not continue the old A/B beginner-product assumptions unless explicitly working on legacy compatibility.

## Build, Test, and Development Commands

From `harmony/`, build the signed debug HAP with:

```bash
DEVECO_SDK_HOME="$PWD/.sdk" /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

Regenerate the catalog after updating upstream data with `node tools/sync_exercise_catalog.mjs`; use `tools/transcode_exercise_media.sh` for media conversion. The HAP is written to `entry/build/default/outputs/default/entry-default-signed.hap`.

From `prototype/`, use `npm run dev` for local preview, `npm run build` for a production build, `npm run test:runtime` for Playwright checks, and `npm run test:sites` for the Sites worker tests. Run `npm run check:runtime` before preview or handoff.

## Coding Style & Naming Conventions

Use two-space indentation, semicolons, explicit ArkTS types, and small feature-local components. Name components and classes in `PascalCase`, methods and variables in `camelCase`, and constants in `UPPER_SNAKE_CASE`. Keep repositories responsible for persistence and snapshots; keep route/UI composition in `AppRoot` and feature components. Preserve the existing theme tokens instead of scattering color literals.

For V2, keep cross-domain aggregation and trend/recommendation rules in service classes rather than adding more business logic to `AppRoot`. UI must not execute SQL directly.

## Testing Guidelines

For prototype changes, add or update Playwright tests using descriptive `.spec` names and run the relevant npm test command. For Harmony changes, require a successful ArkTS type check/HAP build and exercise the affected flow on an emulator or Mate 60 Pro; verify restart, active-workout, rest countdown, and history behavior when state persistence is touched.

Database changes require both fresh-install and V1-to-V2 migration verification. New-install success is not a substitute for migration testing.

## Commit & Pull Request Guidelines

Use short imperative messages with a conventional prefix, matching history (for example, `feat: ...`, `fix: ...`, or `docs: ...`). Pull requests should explain the user-visible behavior and affected modules, link an issue when one exists, list build/test commands run, and include emulator screenshots or recordings for UI changes. Keep generated build output, signing material, and secrets out of commits.

Prefer phase-sized commits from `docs/AGENT_IMPLEMENTATION_PLAN.md`; do not combine database migration, full navigation redesign, nutrition, and program-engine changes into one large unreviewable commit.

## Security & Configuration Tips

Signing configuration is local to DevEco Studio; never commit credentials or private keys. Review upstream dataset licenses and preserve required Gym visual attribution before distributing catalog media.
