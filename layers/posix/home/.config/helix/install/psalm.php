#!/usr/bin/env -S -- php
<?php

declare(strict_types=1);

$uri = "https://github.com/vimeo/psalm/releases/latest/download/psalm.phar";

$binDir = getenv("BIN");
assert($binDir);
$bin = join(DIRECTORY_SEPARATOR, array: [$binDir, "psalm.phar"]);

$output = [];
$code = -1;
exec(join(" ", array: array_map("escapeshellarg", ["get.sh", $uri])), $output, $code);
assert($code === 0, join(PHP_EOL, array: $output));
$file = join(PHP_EOL, array: $output);

assert(copy($file, $bin));
assert(chmod($bin, permissions: 0755));
