#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('English')
require('rbconfig')

$ARGV => [filename, *argv]

parents = Pathname.pwd.join(File.basename(filename)).parent.ascend.to_a

yml = '.rubocop.yml'
conf = parents.lazy.map { it / yml }.find(-> { File.join(ENV.fetch('XDG_CONFIG_HOME'), 'helix', yml) }, &:file?)
argv += ['--config', conf.to_s]
cmd = [RbConfig.ruby, '-rrubocop', '-e', <<~RUBY, '--', *argv]
  ENV['RUBOCOP_TARGET_RUBY_VERSION'] ||= RuboCop::TargetRuby.supported_versions.max.to_s
  exit(RuboCop::CLI.new.run)
RUBY

parents.each do
  gem = it / 'Gemfile'
  if gem.exist? && gem.read.match?(/rubocop/)
    Dir.chdir(it)
    exec(*%w[bundle exec --], *cmd)
  end
end

ENV['GEM_PATH'] = File.join(Dir.home, *%w[.cache helix-rt ruby rubocop])
exec(*cmd)
