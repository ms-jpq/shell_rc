#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('English')
require('pathname')

$ARGV => [filename, *argv]

parents = Pathname.pwd.join(File.basename(filename)).parent.ascend.to_a

yml = '.rubocop.yml'
conf = parents.lazy.map { _1 / yml }.find(-> { File.join(__dir__, '..', yml) }, &:file?)
argv += ['--config', conf.to_s]

parents.each do
  gem = _1 / 'Gemfile'
  if gem.exist? && gem.read.match?(/rubocop/)
    Dir.chdir(_1)
    exec(*%w[bundle exec -- rubocop], *argv)
  end
end

gem_path = ENV['GEM_PATH'] = File.join(Dir.home, *%w[.cache helix-rt ruby rubocop])
cop = File.join(gem_path, *%w[bin rubocop])
exec(cop, *argv)
