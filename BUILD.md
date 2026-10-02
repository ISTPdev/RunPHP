# Building RunPHP

This document describes how to build and test RunPHP from the repository.

RunPHP is written in D and currently targets Windows.

## Requirements

- Windows
- DMD
- A working Windows C/C++ linker environment
- PHP for running the development tests

Verify that DMD is available:

```powershell
dmd --version
```

## Repository Structure

```text
RunPHP/
├── build/
│   ├── tests/
│   │   ├── hello_world.bat
│   │   ├── arguments.bat
│   │   └── arguments_quotes.bat
│   ├── runphp.exe
│   ├── runphp.ini
│   └── runphp.ini.example
├── examples/
├── lib/
├── release/
│   ├── runphp.exe
│   └── runphp.ini
├── src/
│   └── runphp.d
└── build.ps1
```

The directories have separate purposes:

- `src/` contains the RunPHP source code.
- `build/` contains the local development build and development configuration.
- `build/tests/` contains double-clickable development tests.
- `examples/` contains user-facing examples of normal RunPHP usage.
- `lib/` contains reusable PHP helpers used by the examples.
- `release/` contains the files intended for distribution.

## Development Configuration

Development uses its own configuration:

```text
build\runphp.ini
```

This keeps your local PHP path separate from the distributable configuration in:

```text
release\runphp.ini
```

`build\runphp.ini` is machine-specific and is ignored by Git.

A template is provided:

```text
build\runphp.ini.example
```

When `build.ps1` is run without a development configuration, it creates `build\runphp.ini` from this template.

Edit it and configure your local PHP installation:

```ini
[php]
executable=C:\Tools\php83

[scripts]
directory=

[runner]
pause_on_error=false
pause_after_run=false
```

`executable` can point either to `php.exe` directly or to a directory containing `php.exe`.

## Building

From the repository root:

```powershell
.\build.ps1
```

The build process:

1. Compiles `src\runphp.d` to `build\runphp.exe`.
2. Uses `build\runphp.ini` as the development configuration.
3. Tests the newly compiled executable.
4. Copies the verified executable to `release\runphp.exe`.

The release executable is only updated after the development build has been successfully verified.

RunPHP does not need to be installed or added to `PATH` to build the repository.

## Manual Testing

The development executable can be run directly:

```powershell
.\build\runphp.exe .\examples\hello_world.php
```

Arguments can be tested with:

```powershell
.\build\runphp.exe .\examples\arguments.php "Hello World" --width 1920
```

This uses the repository's development executable and configuration rather than an installed copy of RunPHP.

## Double-Click Tests

For quick testing, `build\tests\` contains BAT files that invoke the development executable directly:

```text
build\tests\hello_world.bat
build\tests\arguments.bat
build\tests\arguments_quotes.bat
```

These can be double-clicked from Windows Explorer.

They use repository-relative paths and therefore do not require:

- RunPHP to be installed
- RunPHP to be in `PATH`
- `.php` files to be associated with RunPHP

The BAT files under `examples/` serve a different purpose. They demonstrate the normal commands an installed RunPHP user would use.

For example:

```cmd
runphp arguments "Hello World" --width 1920
```

## Build and Release Files

The following development files are generated locally and should not be committed:

```text
build\runphp.exe
build\runphp.ini
```

They should be present in `.gitignore`:

```gitignore
/build/runphp.exe
/build/runphp.ini
```

The following files are intended to be committed:

```text
build\runphp.ini.example
build\tests\*.bat
release\runphp.ini
release\runphp.exe
```

`release\runphp.ini` is the user-facing configuration template and should contain placeholder paths rather than machine-specific development paths.

For example:

```ini
[php]
executable=C:\path\to\php.exe
```

## Release Build

Before creating a release:

1. Run `build.ps1`.
2. Make sure the build reports `Build verified successfully.`
3. Run the tests under `build\tests\`.
4. Confirm that `release\runphp.ini` contains only distributable placeholder configuration.
5. Package the required files from `release/` and any other user-facing files into the release ZIP.

The release ZIP should not contain machine-specific development configuration or files from the local `build/` directory.