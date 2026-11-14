# DocNook

Offline document suite for Android, built with Flutter: read, scan, convert
and edit documents on the phone, with no account and no internet permission.

- Product and technical spec: `docs/BLUEPRINT.md`
- Decisions log: `docs/decisions.md`
- Rules for contributors (and Claude Code): `CLAUDE.md`
- Release steps: `docs/release/RELEASE_GUIDE.md`

## Commands

| Task | Command |
| --- | --- |
| Run on a phone | `flutter run --flavor direct` |
| All checks | `./tool/check.sh` |
| Release files | `./tool/release.sh` |
| Store graphics | `python tool/make_store_graphics.py` |
| Web privacy policy and terms | `python tool/make_legal_pages.py` |
