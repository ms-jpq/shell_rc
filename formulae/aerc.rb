# frozen_string_literal: true

class Aerc < Formula
  head do
    url('https://github.com/rjarry/aerc.git', branch: 'master')
    depends_on('notmuch' => :build)
  end

  def install
    system('gmake', 'GOFLAGS=-tags=notmuch', "PREFIX=#{prefix}")
    system('gmake', 'install', "PREFIX=#{prefix}")
  end
end
