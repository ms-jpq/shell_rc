#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('English')
require('pathname')

ENV['SOLARGRAPH_CACHE'] = File.join(ENV.fetch('XDG_CACHE_HOME'), 'solargraph')

gem_path = ENV['GEM_PATH'] = File.join(Dir.home, *%w[.cache helix-rt ruby solargraph])
bin = File.join(gem_path, *%w[bin solargraph])
exec(bin, *ARGV)
