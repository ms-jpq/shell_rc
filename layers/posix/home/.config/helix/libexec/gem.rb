#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('pathname')

ARGV.first => [String => pkg]
packages = [pkg, ...stdin.each]
home = Pathname(Dir.home) / '.cache' / 'helix-rt' / 'ruby_modules' / pkg

home.mkpath
system(*%w[gem install --no-document --install-dir], home, *packages, exception: true)
