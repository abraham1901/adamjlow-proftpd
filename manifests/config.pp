# Class: proftpd::config
#
# Parameters:
#
#   [*port*]              - port to bind service.
#   [*service_name*]      - proftpd service name.
#   [*config_file*]       - proftpd.conf configuration file path.
#   [*socket*]            - proftpd socket.
#
# Actions:
#
# Requires:
#
#   class proftpd::server
#
# Usage:
#
#   class { 'proftpd::config':
#     server_name  => $::server_name,
#   }
#
class proftpd::config(

  $use_ipv6           = $proftpd::params::use_ipv6,
  $ident_lookups      = $proftpd::params::ident_lookups,
  $server_name        = $proftpd::params::server_name,
  $server_type        = $proftpd::params::server_type,
  $defer_welcome      = $proftpd::params::defer_welcome,
  $multiline_rfc2228  = $proftpd::params::multiline_rfc2228,
  $default_server     = $proftpd::params::default_server,
  $show_symlinks      = $proftpd::params::show_symlinks,
  $timeout_notransfer = $proftpd::params::timeout_notransfer,
  $timeout_stalled    = $proftpd::params::timeout_stalled,
  $timeout_idle       = $proftpd::params::timeout_idle,
  $display_login      = $proftpd::params::display_login,
  $display_chdir      = $proftpd::params::display_chdir,
  $list_options       = $proftpd::params::list_options,
  $deny_filter        = $proftpd::params::deny_filter,
  $port               = $proftpd::params::port,
  $max_instances      = $proftpd::params::max_instances,
  $user               = $proftpd::params::user,
  $group              = $proftpd::params::group,
  $umask              = $proftpd::params::umask,
  $allow_overwrite    = $proftpd::params::allow_overwrite,
  $transfer_log       = $proftpd::params::transfer_log,
  $system_log         = $proftpd::params::system_log,

  $tls_engine         = $proftpd::params::tls_engine,
  $tls_log            = $proftpd::params::tls_log,
  $tls_protocol       = $proftpd::params::tls_protocol,
  $tls_rsacertfile    = $proftpd::params::tls_rsacertfile,
  $tls_rsacertkey     = $proftpd::params::tls_rsacertkey,
  $tls_options        = $proftpd::params::tls_options,
  $tls_verifyclient   = $proftpd::params::tls_verifyclient,
  $tls_required       = $proftpd::params::tls_required,
  $tls_renegotiate    = $proftpd::params::tls_renegotiate,

  $sql_backend        = $proftpd::params::sql_backend,
  $sql_engine         = $proftpd::params::sql_engine,
  $sql_host           = $proftpd::params::sql_host,
  $sql_dbname         = $proftpd::params::sql_dbname,
  $sql_username       = $proftpd::params::sql_username,
  $sql_password       = $proftpd::params::sql_password,

  $ldap_engine        = $proftpd::params::ldap_engine,
  $ldap_usetls        = $proftpd::params::ldap_usetls,
  $ldap_server        = $proftpd::params::ldap_server,
  $ldap_binddn        = $proftpd::params::ldap_binddn,
  $ldap_users         = $proftpd::params::ldap_users,
) inherits proftpd::params {

  if $tls_engine == 'on' {
    proftpd::mods {'tls': ensure => 'present' }
  } else {
    proftpd::mods {'tls': ensure => 'absent' }
  }

  if $sql_engine == 'on' {
    proftpd::mods {'sql': ensure => 'present' }
    if $sql_backend == 'mysql' {
      proftpd::mods {'mysql': ensure => 'present' }
    }
    elsif $sql_backend == 'pgsql' {
      proftpd::mods {'pgsql': ensure => 'present' }
    }
    elsif $sql_backend == 'sqlite' {
      proftpd::mods {'sqlite': ensure => 'present' }
    }
  } else {
    proftpd::mods {'sql': ensure => 'absent' }
    proftpd::mods {'mysql': ensure => 'absent' }
    proftpd::mods {'pgsql': ensure => 'absent' }
    proftpd::mods {'sqlite': ensure => 'absent' }
  }

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0400',
    notify => Exec['proftpd-reload'],
  }

  file { $config_file:
    content => template('proftpd/proftpd.conf.erb'),
    mode    => '0644',
  }

  file { "$basedir/modules.conf": ensure => 'absent' }
  file { "$basedir/mods-available":
    ensure => 'directory',
    source => "puppet:///modules/proftpd/",
    recurse => true,
    mode => '0644',
  }
  file { "$basedir/mods-enabled": ensure => 'directory' }
  file { "$basedir/tls.conf": ensure => 'absent' }
  file { "$basedir/mods-available/mod_tls.conf":
    content => template('proftpd/mod_tls.conf.erb'),
    mode    => '0644',
  }
  file { "$basedir/ldap.conf": ensure => 'absent' }
  file { "$basedir/mods-available/mod_ldap.conf":
    content => template('proftpd/mod_ldap.conf.erb'),
    mode    => '0644',
  }
  file { "$basedir/sql.conf": ensure => 'absent' }
  file { "$basedir/mods-available/mod_sql.conf":
    content => template('proftpd/mod_sql.conf.erb'),
    mode    => '0644',
  }

#  proftpd::mods {'ldap': ensure => 'present' }
#  proftpd::mods {'mysql': ensure => 'present' }

  # This kind of sucks, that I have to specify a difference resource for
  # reload.  the reason is that I need the service to be started before mods
  # to the config file which can cause a refresh
  exec { 'proftpd-reload':
    command     => "service ${service_name} reload",
    logoutput   => on_failure,
    refreshonly => true,
    path        => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
  }
  exec { 'proftpd-restart':
    command     => "service ${service_name} restart",
    logoutput   => on_failure,
    refreshonly => true,
    path        => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
  }

}