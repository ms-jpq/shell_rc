# frozen_string_literal: true

class Aerc < Formula
  head do
    url('https://github.com/rjarry/aerc.git', branch: 'master')
    depends_on('go' => :build)
    depends_on('notmuch' => :build)
    depends_on('scdoc' => :build)
  end

  def install
    notmuch = Formula['notmuch']
    system(
      'gmake',
      '--',
      "PREFIX=#{prefix}",
      'GOFLAGS=-tags=notmuch',
      "CPATH=#{notmuch.include}",
      "LD_LIBRARY_PATH=#{notmuch.lib}"
    )
    system('gmake', '--', 'install', "PREFIX=#{prefix}")
  end
end
