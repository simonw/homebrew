require 'formula'

class Postgresql <Formula
  @homepage='http://www.postgresql.org/'
  @url='http://ftp2.uk.postgresql.org/sites/ftp.postgresql.org/source/v8.4.2/postgresql-8.4.2.tar.bz2'
  @md5='d738227e2f1f742d2f2d4ab56496c5c6'

  depends_on 'readline'
  depends_on 'libxml2' if MACOS_VERSION < 10.6

  aka 'postgres'

  def install
    ENV.libxml2 # wouldn't compile for justinlilly otherwise
    
    configure_args = [
        "--enable-thread-safety",
        "--with-bonjour",
        "--with-python",
        "--with-perl",
        "--with-gssapi",
        "--with-krb5",
        "--with-openssl",
        "--with-libxml",
        "--with-libxslt",
        "--prefix=#{prefix}",
        "--disable-debug",
    ]

    if MACOS_VERSION >= 10.6 && Hardware.is_64_bit?
        configure_args << "ARCHFLAGS='-arch x86_64'"
    end

    # Fails on Core Duo with O4 and O3
    if Hardware.intel_family == :core
      ENV.O2
    end

    system "./configure", *configure_args
    system "make install"

    (prefix+'org.postgresql.postgres.plist').write startup_plist
  end

  def skip_clean? path
    # NOTE at some point someone should tweak this so it only skips clean
    # for the bits that break the build otherwise
    true
  end

  def caveats; <<-EOS
If this is your first install, create a database with:
    #{HOMEBREW_PREFIX}/bin/initdb #{HOMEBREW_PREFIX}/var/postgres

Automatically load on login with:
    launchctl load -w #{prefix}/org.postgresql.postgres.plist

Or start manually with:
    #{HOMEBREW_PREFIX}/bin/pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres -l #{HOMEBREW_PREFIX}/var/postgres/server.log start

And stop with:
    #{HOMEBREW_PREFIX}/bin/pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres stop -s -m fast

If you want to install the postgres gem, include ARCHFLAGS in the gem install
to avoid issues:

    env ARCHFLAGS="-arch x86_64" gem install postgres

To install gems without sudo, see the Homebrew wiki.
    EOS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>KeepAlive</key>
  <true/>
  <key>Label</key>
  <string>org.postgresql.postgres</string>
  <key>ProgramArguments</key>
  <array>
    <string>#{HOMEBREW_PREFIX}/bin/postgres</string>
    <string>-D</string>
    <string>#{HOMEBREW_PREFIX}/var/postgres</string>
    <string>-r</string>
    <string>#{HOMEBREW_PREFIX}/var/postgres/server.log</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>UserName</key>
  <string>#{`whoami`}</string>
  <key>WorkingDirectory</key>
  <string>#{HOMEBREW_PREFIX}</string>
</dict>
</plist>
    EOPLIST
  end
end
