# @summary Manage configuration for Apache NiFi
#
# Private subclass for Apache NiFi configuration
#
# @api private
class nifi::config (
  Stdlib::Absolutepath $install_root,
  Stdlib::Absolutepath $var_directory,
  Stdlib::Absolutepath $config_directory,
  Hash $nifi_properties,
  String $user,
  String $group,
  String $version,
  Boolean $cluster = false,
  Hash[
    Stdlib::Fqdn, Struct[{id => Integer[1,255]}]
  ] $cluster_nodes = {},
) {

  $software_directory = "${install_root}/nifi-${version}"
  $nifi_properties_file = "${software_directory}/conf/nifi.properties"

  $path_properties = {
    'nifi.nar.working.directory'                   => "${var_directory}/work/nar/",
    'nifi.documentation.working.directory'         => "${var_directory}/work/docs/components",
    'nifi.database.directory'                      => "${var_directory}/database_repository",
    'nifi.flowfile.repository.directory'           => "${var_directory}/flowfile_repository",
    'nifi.content.repository.directory.default'    => "${var_directory}/content_repository",
    'nifi.provenance.repository.directory.default' => "${var_directory}/provenance_repository",
    'nifi.web.jetty.working.directory'             => "${var_directory}/work/jetty",
    'nifi.state.management.configuration.file'     => "${config_directory}/state-management.xml",
  }

  $_nifi_properties = $path_properties + $nifi_properties

  $_nifi_properties.each |String $key, String $value| {
    ini_setting { "nifi property ${key}":
      ensure  => present,
      path    => $nifi_properties_file,
      setting => $key,
      value   => $value,
    }
  }

  $state_management_properties = {
    'local_directory' => "${var_directory}/state/local",
  }

  file { "${config_directory}/state-management.xml":
    ensure  => file,
    content => epp('nifi/state-management.xml.epp', $state_management_properties),
    owner   => 'root',
    group   => $group,
    mode    => '0640',
  }
}
