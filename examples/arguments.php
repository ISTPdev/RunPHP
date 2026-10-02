<?php

echo "RunPHP Arguments" . PHP_EOL;
echo "================" . PHP_EOL;
echo PHP_EOL;

echo "Argument Count: " . ($argc - 1) . PHP_EOL;
echo PHP_EOL;

if ($argc <= 1)
{
    echo "No arguments supplied." . PHP_EOL;
    exit;
}

foreach (array_slice($argv, 1) as $index => $argument)
{
    echo "Argument " . ($index + 1) . ": " . $argument . PHP_EOL;
}