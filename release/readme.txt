RUNPHP
======

Small Windows launcher for PHP scripts.

INSTALL
-------

1. Put these files somewhere permanent:

   C:\Tools\runphp

2. Edit runphp.ini:

   [php]
   executable=C:\path\to\php.exe

   [scripts]
   directory=C:\scripts\php_exec

3. Add C:\Tools\runphp to your Windows PATH.

Optional:
Associate .php files with runphp.exe to run them by
double-clicking them in Windows Explorer.


USAGE
-----

Run a local script:

   runphp test

If test.php isn't in the current directory, runphp
looks in the configured global scripts directory.

Force local:

   runphp --local test

Force global:

   runphp --scripts test

Run a specific file:

   runphp "C:\somewhere\test.php"

Arguments are forwarded to the PHP script:

   runphp test --option value


WORKING DIRECTORY
-----------------

Named scripts use the directory where you ran runphp.

Example:

   C:\Pictures> runphp resize

The script may live in C:\scripts\php_exec, but its
working directory remains C:\Pictures.

Explicit PHP files use the file's own directory.

This makes double-clicked PHP scripts work naturally.


COMMON ISSUES
-------------

PHP Startup: Unable to load dynamic library...

This is a PHP configuration error, not a runphp error.

Check the php.ini used by your configured php.exe.

For example, an old PHP configuration may contain:

   extension=php_gd2.dll
   extension=php_mysql.dll

while your PHP installation no longer contains those
DLL files.

Modern PHP installations may instead contain extensions
such as:

   php_gd.dll
   php_pdo_mysql.dll

Do NOT blindly rename or substitute extensions.

Remove/comment obsolete extension entries if you don't
need them, or configure the correct extension required
by your PHP installation.

You can check which php.ini PHP is loading with:

   php --ini


MORE INFORMATION
----------------

See README.md for full documentation.

Source code is included as runphp.d.

Compile with DMD:

   dmd -O -release -of="runphp.exe" runphp.d

See LICENSE.txt for licensing information.