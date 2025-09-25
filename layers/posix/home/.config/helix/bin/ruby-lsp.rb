#!/usr/bin/env -S -- ruby
# frozen_string_literal: true
# typed: strong

require('pathname')

gem_path = ENV['GEM_PATH'] = File.join(Dir.home, *%w[.cache helix-rt ruby ruby-lsp])
bin = File.join(gem_path, *%w[bin ruby-lsp])
exec(bin, *ARGV)
