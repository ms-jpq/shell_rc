#!/usr/bin/env -S -- php
<?php

declare(strict_types=1);

[, $pkg, $github] = $argv;

$userHome = getenv("HOME");
assert($userHome);

$home = join(DIRECTORY_SEPARATOR, array: [$userHome, ".cache", "helix-rt", "php", $pkg, "bin"]);
$uri = "https://github.com/$github/releases/latest/download/$pkg.phar";
$bin = join(DIRECTORY_SEPARATOR, array: [$home, "$pkg.phar"]);

$output = [];
$code = -1;
exec(join(" ", array: array_map("escapeshellarg", ["get.sh", $uri])), $output, $code);
assert($code === 0, join(PHP_EOL, array: $output));
$file = join(PHP_EOL, array: $output);

if (!is_dir($home)) {
    assert(mkdir($home, recursive: true));
}
assert(chmod($file, permissions: 0755));
assert(copy($file, $bin));
