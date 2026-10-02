# Changelog

## [1.0.1] - 2026-10-02

### Added

- Added automatic `php.exe` detection when `[php] executable` points to a PHP installation directory.
- Added example scripts for testing basic execution, argument forwarding, working directories, and PHP runtime information.
- Added reusable `runphpinfo()` helper.
- Added `build.ps1` for compiling and verifying RunPHP from the repository.
- Added a self-contained development environment under `build/`.
- Added development BAT tests under `build/tests/` which can be double-clicked without installing RunPHP or adding it to `PATH`.
- Added `build/runphp.ini.example` as a template for local development configuration.

### Changed

- `[php] executable` may now point to either a PHP executable or a PHP installation directory containing `php.exe`.
- RunPHP now determines the location of its own executable using the Windows `GetModuleFileNameW` API instead of relying on `argv[0]`.
- Development builds now use their own local `build/runphp.ini` configuration.
- Verified development builds are copied to the `release/` directory.
- Repository development and testing no longer require RunPHP to be installed globally or added to `PATH`.

### Fixed

- Fixed `runphp.ini` being searched for in the current working directory when RunPHP was invoked through `PATH` or a batch file.
- Fixed PHP directories being treated as executable files, resulting in an `Access is denied` process error.
- Improved PHP executable validation and error reporting.

## 1.0.0 - 2026-09-20

Initial release.

### Added

- Run PHP scripts directly with `runphp`.
- Local script resolution.
- Global script directory fallback.
- `--local` and `--scripts` resolution overrides.
- Explicit PHP file path support.
- PHP argument forwarding.
- Working-directory preservation for named scripts.
- Script-directory working directory for explicit files.
- Windows Explorer `.php` file association support.
- Configurable PHP executable and scripts directory via `runphp.ini`.
- Optional pause-after-run and pause-on-error behavior.