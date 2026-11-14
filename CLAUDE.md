# DocNook — offline document suite for Android (Flutter)

Full spec: docs/BLUEPRINT.md. Decisions log: docs/decisions.md. Read both before any task.

## About the human
The project owner is not a programmer. You (Claude Code) write all code, run all
commands, and fix all errors. Explain results in plain English, give exact steps for
anything the owner must do on the phone, and never ask them to edit code by hand.

## Non-negotiable rules
1. Offline first. Do not add INTERNET or ACCESS_NETWORK_STATE unless a feature truly
   needs it and the owner approves it (none does today). tool/check.sh verifies the
   merged release manifest; update the check only together with such an approval.
2. No component may require an account, registration, license key or API key
   (no Syncfusion, no cloud services). Open-source packages only.
3. Before adding a package, check pub.dev for: latest stable version, license, last
   publish date, Android support, and permissions in its manifest. Record it in
   docs/decisions.md with the reason.
4. Work that can exceed ~100 ms (parsing, rendering, converting, OCR, indexing) runs
   through JobRunner in an isolate. Never on the UI thread.
5. No business logic in widgets. Screen -> Riverpod controller -> use case -> repository.
6. domain/ is pure Dart: no Flutter, no plugin imports.
7. UI uses design_system tokens and components only: no raw colors, sizes or paddings.
8. English only, but every user-facing string lives in the ARB file.
9. Every screen implements loading, empty and error states.
10. Tools never modify the original file unless the user picked "overwrite".
11. Never log file paths, file contents or passwords in release builds.
12. Fixtures are generated or openly licensed; never real personal documents.
13. Keep features/monetization/ as an empty seam; add no ads or billing code.

## Workflow
- Work one phase at a time in the order of BLUEPRINT section 11. Do not start the next
  phase until the owner confirms the current phase's "Done when" on their phone.
- For each task: (1) state the requirement IDs it covers, (2) give a short plan and the
  files you will touch, (3) implement in small git commits citing IDs
  (e.g. "feat(pdf): resume position [FR-READ-03]"), (4) add tests, (5) run tool/check.sh.
- End each phase by installing the build on the connected phone
  (flutter run --flavor direct --release) and giving the owner a numbered test checklist.
- If a package or approach fails a spike, stop, explain in plain English, propose an
  alternative that follows rule 2, and log it.
- Ask the owner before: adding a permission, changing a shipped database schema,
  changing design tokens, or cutting scope.
- Update the checkboxes in BLUEPRINT section 11 as tasks finish.

## Commands
- Run on phone:  flutter run --flavor direct
- Codegen:       dart run build_runner build --delete-conflicting-outputs
- All checks:    ./tool/check.sh
- Release:       see BLUEPRINT sections 12.4 and 12.5

## Definition of done (every task)
- Meets its requirement IDs; works in airplane mode.
- Light + dark theme, 200% font scale, TalkBack labels.
- Tests added and passing; tool/check.sh clean.
- No jank on the reference device for scrolling screens.
