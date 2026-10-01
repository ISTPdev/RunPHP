import std.algorithm : startsWith;
import std.array : array;
import std.conv : to;
import std.file : chdir, exists, getcwd, isFile, readText;
import std.path :
    absolutePath,
    baseName,
    buildPath,
    dirName,
    extension,
    setExtension;
import std.process :
    Config,
    environment,
    execute,
    spawnProcess,
    wait;
import std.stdio :
    stderr,
    stdin,
    stdout,
    write,
    writefln,
    writeln;
import std.string :
    indexOf,
    splitLines,
    strip,
    toLower;
import std.typecons : Tuple, tuple;


// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------

struct ConfigFile
{
    string phpExecutable;
    string scriptsDirectory;

    bool pauseOnError = true;
    bool pauseAfterRun = false;
}


ConfigFile load_config(string executableDirectory)
{
    ConfigFile config;

    string configPath = buildPath(executableDirectory, "runphp.ini");

    if (!exists(configPath))
    {
        fail(
            "Configuration file not found:\n" ~
            configPath ~ "\n\n" ~
            "Create runphp.ini beside runphp.exe."
        );
    }

    string currentSection;

    foreach (rawLine; readText(configPath).splitLines())
    {
        string line = rawLine.strip();

        if (line.length == 0)
            continue;

        if (line.startsWith("#") || line.startsWith(";"))
            continue;

        if (
            line.length >= 2 &&
            line[0] == '[' &&
            line[$ - 1] == ']'
        )
        {
            currentSection = line[1 .. $ - 1].strip().toLower();
            continue;
        }

        ptrdiff_t equalsPosition = line.indexOf('=');

        if (equalsPosition < 0)
            continue;

        string key = line[0 .. equalsPosition].strip().toLower();
        string value = line[equalsPosition + 1 .. $].strip();

        if (currentSection == "php")
        {
            if (key == "executable")
                config.phpExecutable = value;
        }
        else if (currentSection == "scripts")
        {
            if (key == "directory")
                config.scriptsDirectory = value;
        }
        else if (currentSection == "runner")
        {
            if (key == "pause_on_error")
                config.pauseOnError = parse_bool(value);

            if (key == "pause_after_run")
                config.pauseAfterRun = parse_bool(value);
        }
    }

    if (config.phpExecutable.length == 0)
    {
        fail(
            "Missing configuration value:\n\n" ~
            "[php]\n" ~
            "executable=..."
        );
    }

    if (!exists(config.phpExecutable))
    {
        fail(
            "Configured PHP executable does not exist:\n" ~
            config.phpExecutable
        );
    }

    if (config.scriptsDirectory.length != 0)
    {
        config.scriptsDirectory =
            absolutePath(config.scriptsDirectory);
    }

    return config;
}


bool parse_bool(string value)
{
    string normalized = value.strip().toLower();

    return
        normalized == "true" ||
        normalized == "yes" ||
        normalized == "1" ||
        normalized == "on";
}


// -----------------------------------------------------------------------------
// Command-line options
// -----------------------------------------------------------------------------

enum ResolutionMode
{
    automatic,
    localOnly,
    scriptsOnly
}


struct Options
{
    ResolutionMode resolutionMode = ResolutionMode.automatic;

    bool pauseAfterRun = false;
    bool noPause = false;
    bool showHelp = false;

    string script;
    string[] scriptArguments;
}


Options parse_arguments(string[] arguments)
{
    Options options;

    bool parsingRunnerArguments = true;

    foreach (argument; arguments[1 .. $])
    {
        if (
            parsingRunnerArguments &&
            argument == "--"
        )
        {
            parsingRunnerArguments = false;
            continue;
        }

        if (
            parsingRunnerArguments &&
            options.script.length == 0
        )
        {
            switch (argument)
            {
                case "--local":
                    options.resolutionMode =
                        ResolutionMode.localOnly;
                    continue;

                case "--scripts":
                    options.resolutionMode =
                        ResolutionMode.scriptsOnly;
                    continue;

                case "--pause":
                    options.pauseAfterRun = true;
                    continue;

                case "--no-pause":
                    options.noPause = true;
                    continue;

                case "--help":
                case "-h":
                case "/?":
                    options.showHelp = true;
                    continue;

                default:
                    break;
            }
        }

        if (options.script.length == 0)
        {
            options.script = argument;

            // Once we've found the script, every remaining
            // argument belongs to the PHP script.
            parsingRunnerArguments = false;
        }
        else
        {
            options.scriptArguments ~= argument;
        }
    }

    return options;
}


// -----------------------------------------------------------------------------
// Script resolution
// -----------------------------------------------------------------------------

struct ResolvedScript
{
    string path;
    string workingDirectory;
    string source;
}


ResolvedScript resolve_script(
    string requestedScript,
    ResolutionMode mode,
    string scriptsDirectory
)
{
    string invocationDirectory = getcwd();
    string scriptName = requestedScript;

    // Add .php when no extension was supplied.
    if (extension(scriptName).length == 0)
        scriptName ~= ".php";


    // -------------------------------------------------------------------------
    // Explicit path
    //
    // Examples:
    //
    //     runphp C:\tools\thing.php
    //     runphp .\thing.php
    //     runphp ..\thing.php
    //
    // If the argument contains path information, don't search elsewhere.
    // -------------------------------------------------------------------------

    if (contains_path_information(scriptName))
    {
        string candidate = absolutePath(scriptName);

        if (!valid_script(candidate))
        {
            fail(
                "PHP script not found:\n" ~
                candidate
            );
        }

        return ResolvedScript(
            candidate,
            dirName(candidate),
            "explicit path"
        );
    }


    // -------------------------------------------------------------------------
    // Current directory
    // -------------------------------------------------------------------------

    if (
        mode == ResolutionMode.automatic ||
        mode == ResolutionMode.localOnly
    )
    {
        string candidate =
            absolutePath(scriptName);

        if (valid_script(candidate))
        {
            return ResolvedScript(
                candidate,
                invocationDirectory,
                "scripts directory"
            );
        }
    }


    // -------------------------------------------------------------------------
    // Global scripts directory
    // -------------------------------------------------------------------------

    if (
        mode == ResolutionMode.automatic ||
        mode == ResolutionMode.scriptsOnly
    )
    {
        if (scriptsDirectory.length == 0)
        {
            if (mode == ResolutionMode.scriptsOnly)
            {
                fail(
                    "No global scripts directory is configured.\n\n" ~
                    "Add this to runphp.ini:\n\n" ~
                    "[scripts]\n" ~
                    "directory=C:\\scripts\\php_exec"
                );
            }
        }
        else
        {
            string candidate =
                absolutePath(
                    buildPath(
                        scriptsDirectory,
                        scriptName
                    )
                );

            if (valid_script(candidate))
            {
                return ResolvedScript(
                    candidate,
                    dirName(candidate),
                    "scripts directory"
                );
            }
        }
    }


    // -------------------------------------------------------------------------
    // Nothing found
    // -------------------------------------------------------------------------

    string message =
        "PHP script not found:\n\n" ~
        requestedScript ~ "\n\n";


    final switch (mode)
    {
        case ResolutionMode.automatic:
            message ~=
                "Searched:\n" ~
                "  " ~ absolutePath(scriptName);

            if (scriptsDirectory.length != 0)
            {
                message ~=
                    "\n  " ~
                    buildPath(
                        scriptsDirectory,
                        scriptName
                    );
            }

            break;


        case ResolutionMode.localOnly:
            message ~=
                "Local search only:\n" ~
                "  " ~ absolutePath(scriptName);
            break;


        case ResolutionMode.scriptsOnly:
            message ~=
                "Global scripts search only:\n" ~
                "  " ~
                buildPath(
                    scriptsDirectory,
                    scriptName
                );
            break;
    }

    fail(message);

    assert(0);
}


bool valid_script(string path)
{
    return
        exists(path) &&
        isFile(path);
}


bool contains_path_information(string path)
{
    if (path.length >= 2 && path[1] == ':')
        return true;

    if (path.startsWith("\\\\"))
        return true;

    if (path.startsWith("./"))
        return true;

    if (path.startsWith(".\\"))
        return true;

    if (path.startsWith("../"))
        return true;

    if (path.startsWith("..\\"))
        return true;

    if (path.indexOf('/') >= 0)
        return true;

    if (path.indexOf('\\') >= 0)
        return true;

    return false;
}


// -----------------------------------------------------------------------------
// PHP execution
// -----------------------------------------------------------------------------

int execute_php(
    ConfigFile config,
    ResolvedScript script,
    string[] scriptArguments
)
{
    string[] command;

    command ~= config.phpExecutable;
    command ~= script.path;
    command ~= scriptArguments;

    try
    {
        if (script.source == "explicit path")
        {
            chdir(script.workingDirectory);
        }
        auto process = spawnProcess(
            command,
            stdin,
            stdout,
            stderr
        );

        return wait(process);
    }
    catch (Exception exception)
    {
        stderr.writeln(
            "ERROR: Failed to start PHP.\n\n",
            "PHP executable:\n",
            config.phpExecutable,
            "\n\n",
            "Script:\n",
            script.path,
            "\n\n",
            "Working directory:\n",
            script.workingDirectory,
            "\n\n",
            exception.msg
        );

        return 1;
    }
}


// -----------------------------------------------------------------------------
// Utility
// -----------------------------------------------------------------------------

void pause()
{
    write("\nPress Enter to close...");
    stdout.flush();

    stdin.readln();
}


void fail(string message)
{
    stderr.writeln(
        "\nrunphp error\n",
        "============\n",
        message
    );

    throw new Exception(message);
}


void print_help()
{
    writeln(
`runphp - PHP script launcher

USAGE

    runphp <script> [arguments...]

    runphp --local <script> [arguments...]

    runphp --scripts <script> [arguments...]

OPTIONS

    --local
        Only look in the current directory.

    --scripts
        Only look in the configured global scripts directory.

    --pause
        Wait for Enter after PHP finishes.

    --no-pause
        Never pause after execution.

    --help
        Show this help.

SCRIPT RESOLUTION

    runphp cleanup

        Searches:

            .\cleanup.php

        followed by:

            <scripts_directory>\cleanup.php


    runphp --local cleanup

        Searches only:

            .\cleanup.php


    runphp --scripts cleanup

        Searches only:

            <scripts_directory>\cleanup.php


    runphp "D:\Tools\cleanup.php"

        Runs that exact file.


ARGUMENT FORWARDING

    runphp resize --width 800 --recursive

    becomes conceptually:

        php resize.php --width 800 --recursive


EXPLORER

    Associate .php files with runphp.exe.

    Windows supplies the selected PHP file as the first argument.

    runphp changes PHP's working directory to the directory
    containing the PHP script before starting PHP.
`);
}


// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

int main(string[] arguments)
{
    bool shouldPauseOnError = true;

    try
    {
        string executablePath =
            absolutePath(arguments[0]);

        string executableDirectory =
            dirName(executablePath);

        ConfigFile config =
            load_config(executableDirectory);

        shouldPauseOnError =
            config.pauseOnError;

        Options options =
            parse_arguments(arguments);


        if (options.showHelp)
        {
            print_help();
            return 0;
        }


        if (options.script.length == 0)
        {
            stderr.writeln(
                "ERROR: No PHP script was specified.\n\n",
                "Example:\n",
                "    runphp cleanup\n\n",
                "For help:\n",
                "    runphp --help"
            );

            if (shouldPauseOnError)
                pause();

            return 1;
        }


        ResolvedScript script =
            resolve_script(
                options.script,
                options.resolutionMode,
                config.scriptsDirectory
            );


        int exitCode =
            execute_php(
                config,
                script,
                options.scriptArguments
            );


        bool shouldPause =
            !options.noPause &&
            (
                options.pauseAfterRun ||
                config.pauseAfterRun ||
                (
                    exitCode != 0 &&
                    config.pauseOnError
                )
            );


        if (shouldPause)
            pause();


        return exitCode;
    }
    catch (Exception exception)
    {
        // fail() already prints its detailed message.
        //
        // This catch mainly prevents D's normal exception dump
        // from being the user-facing error interface.

        if (shouldPauseOnError)
            pause();

        return 1;
    }
}