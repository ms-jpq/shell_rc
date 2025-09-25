#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('pathname')

gem_path = ENV['GEM_PATH'] = File.join(Dir.home, *%w[.cache helix-rt ruby sorbet])
bin = File.join(gem_path, *%w[bin srb])
exec(bin, *ARGV)
