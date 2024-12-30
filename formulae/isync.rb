# frozen_string_literal: true

class Isync < Formula
  head do
    url 'https://git.code.sf.net/p/isync/isync.git', branch: 'master'
    depends_on 'autoconf' => :build
    depends_on 'automake' => :build
  end

  depends_on 'berkeley-db@5'
  depends_on 'openssl@3'
  depends_on 'cyrus-sasl'

  uses_from_macos 'zlib'

  def install
    sasl = HOMEBREW_PREFIX / 'opt' / 'cyrus-sasl'
    system('./autogen.sh') if build.head?
    system('./configure', *std_configure_args, '--disable-silent-rules', "--with-sasl=#{sasl}")
    system('make', 'install')
  end

  service do
    sasl = [
      HOMEBREW_PREFIX / 'opt' / 'cyrus-sasl' / 'lib' / 'sasl2',
      HOMEBREW_PREFIX / 'opt' / 'cyrus-sasl-xoauth2' / 'lib' / 'sasl2'
    ].join(File::PATH_SEPARATOR)

    run [opt_bin / 'mbsync', '--all']
    run_type :interval
    interval 300
    keep_alive false
    environment_variables PATH: std_service_path_env, SASL_PATH: sasl
    log_path File::NULL
    error_log_path File::NULL
  end

  test do
    system bin / 'mbsync-get-cert', 'duckduckgo.om:443'
  end
end
