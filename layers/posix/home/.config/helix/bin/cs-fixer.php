#!/usr/bin/env -S -- php
<?php

declare(strict_types=1);

$cwd = getcwd();
assert($cwd);
$tmp = tempnam($cwd, prefix: "~php-cs-fixer~");
assert($tmp);

try {
    $data = file_get_contents("php://stdin");
    assert($data);
    assert(file_put_contents($tmp, data: $data));

    $output = [];
    $code = -1;
    exec(
        join(
            " ",
            array_map("escapeshellarg", [PHP_BINARY, "-l", $tmp]),
        ),
        $output,
        $code
    );
    assert($code === 0, join(PHP_EOL, $output));

    exec(
        join(
            " ",
            array_map("escapeshellarg", ["php-cs-fixer", "--no-interaction", "fix", "--", $tmp])
        ),
        $output,
        $code
    );
    assert($code === 0, join(PHP_EOL, $output));

    $data = file_get_contents($tmp);
    assert($data);

    echo $data;
} finally {
    assert(unlink($tmp));
}
