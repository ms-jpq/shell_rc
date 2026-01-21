#!/usr/bin/env -S -- php
<?php

declare(strict_types=1);

[,$pkg] = $argv;

$userHome = getenv("HOME");
assert($userHome);

$json = json_encode([
    "require" => array_fill_keys([$pkg, ...array_slice($argv, offset: 2)], value: "*")
]);
assert($json);
$home = join(DIRECTORY_SEPARATOR, array: [$userHome, ".cache", "helix-rt", "php", str_replace(DIRECTORY_SEPARATOR, replace: "-", subject: $pkg)]);

if (!is_dir($home)) {
    assert(mkdir($home, recursive: true));
}
assert(file_put_contents(join(DIRECTORY_SEPARATOR, array: [$home, "composer.json"]), data: $json));

$composer = [
    "composer",
    "--no-scripts",
    "--no-interaction",
    "--no-plugins",
    "--working-dir",
    $home,
    "install",
];


$tmp = join(DIRECTORY_SEPARATOR, array: [sys_get_temp_dir(), "composer"]);
assert(putenv("COMPOSER_CACHE_DIR=$tmp"));

$output = [];
$code = -1;
exec(
    join(" ", array_map("escapeshellarg", $composer)),
    $output,
    $code
);
assert($code === 0, join(PHP_EOL, $output));
