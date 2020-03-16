# @summary Manage configuration for Apache NiFi
#
# Private subclass for Apache NiFi configuration
#
# @api private
class nifi::config (
  Stdlib::Absolutepath $install_root,
  Stdlib::Absolutepath $var_directory,
  Hash $nifi_properties,
  String $user,
  String $group,
  String $version,
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
  }

  $_nifi_properties = $path_properties + $nifi_properties

  file { $var_directory:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  $_nifi_properties.each |String $key, String $value| {
    ini_setting { "nifi property ${key}":
      ensure  => present,
      path    => $nifi_properties_file,
      setting => $key,
      value   => $value,
    }
  }

  augeas { 'nifi local state directory':
    root    => "${software_directory}/conf",
    incl    => '/state-management.xml',
    lens    => 'Xml.lns',
    changes => [
      "set stateManagement/local-provider/property[#attribute/name='Directory']/#text ${var_directory}/state/local",

    ]
  }
}
