# Changelog

All notable changes to BBT HRMS are recorded here. Versions follow Semantic Versioning (`MAJOR.MINOR.PATCH`) and Flutter build numbers increase with every distributable build.

## [1.2.1+6] - 2026-07-30

### Fixed

- Display the mandatory uploaded profile photo in the HR Profile screen instead of always showing the placeholder icon.
- Keep a safe placeholder when the stored profile image is unavailable or cannot be loaded.

## [1.2.0+5] - 2026-07-30

### Changed

- Replaced the default Flutter launcher icon with the official BitByte logo.
- Added adaptive Android, iOS, web, Windows, and macOS launcher-icon generation.

## [1.1.2+4] - 2026-07-30

### Fixed

- Declared Pillow as a direct backend dependency so clean Render deployments can start the image-validation code.
- Cleared stale Flutter/Dart processes that were blocking local Android build commands.

## [1.1.1+3] - 2026-07-30

### Fixed

- Fixed valid display-picture uploads being rejected when Android supplied an incorrect or missing MIME type.
- Added content-based JPG, PNG, and WebP validation and explicit Flutter multipart image types.

## [1.1.0+2] - 2026-07-30

### Changed

- Renamed the user-facing application from `hrms_mobileapp_bitbyte` / `BitByte HRMS` to `BBT HRMS` across Android, iOS, web, Windows, Linux, macOS, notifications, and downloads.
- Added live refresh behavior for CEO metrics after workflow actions.
- Expanded HR employee, attendance, profile, and settings flows.
- Made display-picture collection mandatory for new and existing users.
- Improved employee registration calendars, LOVs, bank verification, document uploads, and submission feedback.

## [1.0.0+1] - Initial Release

- Initial Flutter HRMS application release.
