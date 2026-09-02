# Repository Guidelines

## Project Structure

`harmony/` contains the production HarmonyOS NEXT app. ArkTS source lives in `harmony/entry/src/main/ets/`: app composition in `app/`, screens in `features/`, shared UI in `components/`, domain models in `domain/`, and persistence in `data/`. Catalog JSON and exercise media are under `harmony/entry/src/main/resources/`; maintenance scripts are in `harmony/tools/`. `prototype/` is the browser visual prototype. Product requirements, implementation plans, and reference screenshots live in `docs/` and `docs/效果图/`.

## V2 Source of Truth

For V2 work, read these documents in order: `docs/PRODUCT_SPEC.md`, `docs/DATABASE_DESIGN.md`, `docs/PAGE_STRUCTURE.md`, `docs/AGENT_IMPLEMENTATION_PLAN.md`, then `docs/IMPLEMENTATION_REFERENCE.md`. Earlier documents win on conflicts. The product is goal-driven fat-loss and strength training; the old A/B flow is compatibility-only. Keep persistence and snapshots in repositories, aggregation/trends/recommendations in services, and SQL out of UI.

## Build and Test

From `harmony/`, build the signed debug HAP:

```bash
DEVECO_SDK_HOME="$PWD/.sdk" /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

The artifact is `harmony/entry/build/default/outputs/default/entry-default-signed.hap`. Verify affected flows on an emulator or Mate 60 Pro. Database changes require both fresh-install and V1→V2 migration checks, including restart, active-workout recovery, rest countdown, and history when applicable. Prototype checks run from `prototype/` with `npm run build`, `npm run test:runtime`, and `npm run test:sites`.

## Style and Naming

Use two-space indentation, semicolons, explicit ArkTS types, and small feature-local components. Classes/components use `PascalCase`, methods and variables `camelCase`, and constants `UPPER_SNAKE_CASE`. Preserve theme tokens. Prefer phase-sized changes and keep legacy compatibility explicit.

## Commits and Pull Requests

Use short imperative conventional prefixes such as `feat:`, `fix:`, and `docs:`. PRs should describe user-visible behavior and affected modules, link an issue when available, list verification commands, and attach emulator screenshots for UI changes. Do not commit generated build output, credentials, or signing keys.

## Security

Keep signing configuration local. Review upstream catalog/media licensing and retain required attribution before distribution.
