RunPHP
======

RunPHP is a small Windows utility for running PHP scripts from the command line or Windows Explorer.


SETUP
-----

1. Edit runphp.ini and configure your PHP installation.

You can specify the PHP executable:

    [php]
    executable=C:\Tools\php83\php.exe

Or the PHP installation directory:

    [php]
    executable=C:\Tools\php83

When a directory is specified, RunPHP automatically looks for php.exe inside it.

2. Add the directory containing runphp.exe to your Windows PATH if you want to use the "runphp" command from any terminal.


USAGE
-----

    runphp <script> [arguments...]

Examples:

    runphp example
    runphp example.php
    runphp resize --width 800 --recursive
    runphp "D:\Tools\example.php"

Run:

    runphp --help

for additional options and script resolution information.


CONFIGURATION
-------------

runphp.ini must be located beside runphp.exe.

An optional global scripts directory can be configured with:

    [scripts]
    directory=C:\Tools\PHP-Scripts

Runner behavior can be configured with:

    [runner]
    pause_on_error=true
    pause_after_run=false


TROUBLESHOOTING
---------------

"Configuration file not found"

    Make sure runphp.ini is beside runphp.exe.

"PHP executable not found"

    Check the [php] executable setting in runphp.ini.

"runphp is not recognized as a command"

    Add the directory containing runphp.exe to your Windows PATH.


LICENSE
-------

RunPHP is released under the Unlicense.