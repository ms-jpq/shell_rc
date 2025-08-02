#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('pathname')

return if /^2/ =~ RUBY_VERSION

ARGV => [pkg, *pkgs]
home = Pathname(Dir.home) / '.cache' / 'helix-rt' / 'ruby' / pkg

exec(*%w[gem install --no-document --install-dir], home.to_s, pkg, *pkgs)
