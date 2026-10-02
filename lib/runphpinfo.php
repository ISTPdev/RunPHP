<?php

function runphpinfo()
{
    $iniFile = php_ini_loaded_file();

    echo "RunPHP Information" . PHP_EOL;
    echo "==================" . PHP_EOL;
    echo PHP_EOL;

    echo "PHP" . PHP_EOL;
    echo "---" . PHP_EOL;
    echo "Version:          " . PHP_VERSION . PHP_EOL;
    echo "Binary:           " . PHP_BINARY . PHP_EOL;
    echo "SAPI:             " . PHP_SAPI . PHP_EOL;
    echo "Operating System: " . PHP_OS . PHP_EOL;
    echo "Architecture:     " . (PHP_INT_SIZE * 8) . "-bit" . PHP_EOL;
    echo PHP_EOL;

    echo "Configuration" . PHP_EOL;
    echo "-------------" . PHP_EOL;
    echo "php.ini:          " . ($iniFile ?: "None") . PHP_EOL;
    echo "Extension Dir:    " . ini_get("extension_dir") . PHP_EOL;
    echo PHP_EOL;

    echo "Script" . PHP_EOL;
    echo "------" . PHP_EOL;
    echo "Current Dir:      " . getcwd() . PHP_EOL;
}