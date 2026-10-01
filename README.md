# RUNPHP

runphp is a small Windows launcher for PHP scripts.

It allows PHP scripts to be launched from the command line or directly
from Windows Explorer without requiring a separate .bat file for every
script.

## FILES

`runphp.exe` The compiled launcher.

`runphp.ini` Configuration file.

`runphp.d` D source code for runphp.

`LICENSE.txt` License information.

## INSTALLATION

1. Extract the files to a permanent directory, for example:

   ```
   C:\Tools\runphp
   ```

2. Edit runphp.ini and configure your PHP executable:

   ```
   [php]
   executable=C:\path\to\php.exe
   ```

3. Configure the **optional** global PHP scripts directory: (this is where you put your scripts you want to run directly from the terminal like "hello_world.php" will call "runphp hello_world.php" where hello_world.php lives inside the php_exec director )

   ```
   [scripts]
   directory=C:\scripts\php_exec
   ```

4. Add the runphp directory to your Windows user PATH:

   ```
   C:\Tools\runphp
   ```

You can now use "runphp" from any terminal.

## USAGE

Run a script from the current directory:

```
runphp test
```

This looks for:

```
.\test.php
```

If no local script exists, RunPHP looks in the configured global scripts
directory.

Force the local script:

```
runphp --local test
```

Force the global script:

```
runphp --scripts test
```

Run an explicit PHP file:

```
runphp "C:\some folder\test.php"
```

Pass arguments to a PHP script:

```
runphp test --width 1920 --height 1080
```

Arguments following the script name are passed directly to PHP.

## WORKING DIRECTORY

Named scripts preserve the directory from which RunPHP was invoked.

For example:

```
C:\Pictures> runphp resize
```

may execute:

```
C:\scripts\php_exec\resize.php
```

while the PHP working directory remains:

```
C:\Pictures
```

This allows globally stored PHP utilities to operate on the current
directory.

Explicit PHP file paths use the directory containing the PHP file as the
working directory.

For example:

```
runphp "D:\Tools\cleanup.php"
```

runs cleanup.php with:

```
D:\Tools
```

as its working directory.

## WINDOWS EXPLORER

.php files can be associated with runphp.exe using:

```
Right Click PHP File
-> Open With
-> Choose another app
-> Choose an app on your PC
-> Select runphp.exe
```

You can optionally tell Windows to always use runphp.exe for .php files.

Double-clicking a PHP file will then execute the file with its own
directory as the working directory.

## CONFIGURATION

Example runphp.ini:

```
[php]
executable=C:\xampp\php\php.exe

[scripts]
directory=C:\scripts\php_exec

[runner]
pause_on_error=true
pause_after_run=false
```

Set pause_after_run=true if you want the terminal window to remain open
after a script finishes.

## COMPILING

runphp is written in D and can be compiled using DMD:

```
dmd -O -release -of="runphp.exe" runphp.d
```

## LICENSE

```
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
```