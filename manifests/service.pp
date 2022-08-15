# @summary Manage the Apache NiFi service
#
# Private subclass for running Apache NiFi as a service
#
# @api private
class nifi::service (
  Stdlib::Absolutepath $install_root,
  String $version,
  String $user,
  Integer[0] $limit_nofile,
  Integer[0] $limit_nproc,
  Stdlib::Absolutepath $log_directory = '/var/log/nifi',
) {
  $service_params = {
    'nifi_home'     => "${install_root}/nifi-${version}",
    'user'          => $user,
    'limit_nofile'  => $limit_nofile,
    'limit_nproc'   => $limit_nproc,
    'log_directory' => $log_directory,
  }

  systemd::unit_file { 'nifi.service':
    content => epp('nifi/nifi.service.epp', $service_params),
    enable  => true,
    active  => true,
  }
}
