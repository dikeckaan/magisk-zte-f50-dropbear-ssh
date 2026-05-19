# Changelog

## v1.0.2 — 2026-05-19
- **Service migration to `bin-utils/lib/common.sh`** (now a hard dep,
  v1.3.0+ required). `service.sh` uses `wait_for_file` for the
  authorized_keys wait, `log_line` for timestamped logging, and
  `log_rotate` for log management. Net: 76 → 58 lines.
- `customize.sh` now hard-requires bin-utils v1.3.0+ at install time.
- Behaviour unchanged: same port 22222, same bind-mount trick, same
  host-key generation on first boot, same supervisor loop.

## v1.0.1 — 2026-05-19
- customize.sh translated to English (Phase 3 from the i18n plan).

## v1.0.0
- Initial public release
