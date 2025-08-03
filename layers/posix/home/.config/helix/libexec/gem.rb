#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('pathname')

return if (/^2/ =~ RUBY_VERSION) || (Gem.win_platform? && ENV.key?("CI"))

ARGV => [pkg, *pkgs]
home = Pathname(Dir.home) / '.cache' / 'helix-rt' / 'ruby' / pkg

# TODO: https://github.com/ruby/prism/pull/2711
ENV['ARFLAGS'] = '-r'
exec(*%w[gem install --no-document --install-dir], home.to_s, pkg, *pkgs)
