$ar_databases = ['activerecord_unittest', 'activerecord_unittest2']
$as_vagrant   = 'sudo -u vagrant -H bash -l -c'
$home         = '/home/vagrant'

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'apt-get -y update':
    unless => "test -e ${home}/.rvm"
  }
}
class { 'apt_get_update':
  stage => preinstall
}

package { 'python-software-properties':
    ensure => present,
}

# --- MongoDB ---------------
package { 'mongodb':
  ensure => present,
}

service { 'mongodb':
  ensure  => running,
  require => Package['mongodb'],
}

# --- SQLite -------------------------------------------------------------------

package { ['sqlite3', 'libsqlite3-dev']:
  ensure => installed;
}

# --- MySQL --------------------------------------------------------------------

class install_mysql {
  class { 'mysql': }

  class { 'mysql::server':
    config_hash => { 'root_password' => '' }
  }

  database { $ar_databases:
    ensure  => present,
    charset => 'utf8',
    require => Class['mysql::server']
  }

  database_user { 'rails@localhost':
    ensure  => present,
    require => Class['mysql::server']
  }

  database_grant { ['rails@localhost/activerecord_unittest', 'rails@localhost/activerecord_unittest2']:
    privileges => ['all'],
    require    => Database_user['rails@localhost']
  }

  package { 'libmysqlclient15-dev':
    ensure => installed
  }
}
class { 'install_mysql': }

# --- PostgreSQL ---------------------------------------------------------------

class install_postgres {
  class { 'postgresql': }

  class { 'postgresql::server': }

  pg_database { $ar_databases:
    ensure   => present,
    encoding => 'UTF8',
    require  => Class['postgresql::server']
  }

  pg_user { 'rails':
    ensure  => present,
    require => Class['postgresql::server']
  }

  pg_user { 'vagrant':
    ensure    => present,
    superuser => true,
    require   => Class['postgresql::server']
  }

  package { 'libpq-dev':
    ensure => installed
  }

  package { 'postgresql-contrib':
    ensure  => installed,
    require => Class['postgresql::server'],
  }
}
class { 'install_postgres': }

# --- Memcached ----------------------------------------------------------------

class { 'memcached': }

# --- Packages -----------------------------------------------------------------

package { 'curl':
  ensure => installed
}

package { 'build-essential':
  ensure => installed
}

package { 'git-core':
  ensure => installed
}

# Nokogiri dependencies.
package { ['libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed
}

# ExecJS runtime.
package { 'nodejs':
  ensure => installed
}

# --- Ruby ---------------------------------------------------------------------

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm/bin/rvm",
  require => Package['curl']
}

exec { 'install_ruby':
  # We run the rvm executable directly because the shell function assumes an
  # interactive environment, in particular to display messages or ask questions.
  # The rvm executable is more suitable for automated installs.
  #
  # Thanks to @mpapis for this tip.
  command => "${as_vagrant} '${home}/.rvm/bin/rvm install ruby-2.0.0-p0 --autolibs=enabled && rvm --fuzzy alias create default ruby-2.0.0-p0'",
  creates => "${home}/.rvm/bin/ruby",
  require => Exec['install_rvm']
}

exec { "${as_vagrant} 'gem install bundler --no-rdoc -/-no-ri'":
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['install_ruby']
}

# --- Redis -----
package { 'redis-server':
  ensure => present,
}

service { 'redis-server':
  ensure  => running,
  require => Package['redis-server'],
}

# --- bash_profile ----

exec {"echo 'alias ll=\"ls -l\"' >> ${home}/.bash_profile":
    onlyif => "test `grep -c 'll=' ${home}/.bash_profile` = `echo 0`"
}

exec {"echo 'export DISPLAY=:99' >> ${home}/.bash_profile":
    onlyif => "test `grep -c 'DISPLAY=:99' ${home}/.bash_profile` = `echo 0`"
}

exec {"echo 'export PS1=\"\e[0;33m[\u@\h \W]\$ \e[m \"' >> ${home}/.bash_profile":
    onlyif => "test `grep -c 'PS1=' ${home}/.bash_profile` = `echo 0`"
}

# --- vim ------
package { 'vim':
    ensure => present,
}

# --- rails ------
package { 'rails':
    ensure => present,
}

# --- ntp -------
package { 'ntp':
    ensure => present,
}

# --- xvfb -------

class xvfb {
    package { 'xvfb':
        ensure => present,
    }

    exec { 'Xvfb :99 -ac':
        subscribe => Package['xvfb']
    }
}

include xvfb

# --- Firefox -----
exec { 'sudo add-apt-repository ppa:ubuntu-mozilla-security/ppa -y':
}

exec { 'sudo apt-get update':
}

package { 'firefox':
    ensure => present,
}
