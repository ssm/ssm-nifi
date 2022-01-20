# @summary Manage configuration for Apache NiFi
#
# Private subclass for Apache NiFi configuration
#
# @api private
class nifi::config (
  Stdlib::Absolutepath $install_root,
  Stdlib::Absolutepath $var_directory,
  Stdlib::Absolutepath $config_directory,
  String $user,
  String $group,
  String $version,
  Boolean $cluster = false,
  Hash[
    Stdlib::Fqdn, Struct[{id => Integer[1,255]}]
  ] $cluster_nodes = {},
  Stdlib::Fqdn $cluster_node_address = $trusted['certname'],
  Stdlib::Port::Unprivileged $cluster_node_protocol_port = 11443,
  Optional[String] $initial_admin_identity = undef,
  Hash[String,Nifi::Property] $nifi_properties = {},
) {

  $software_directory = "${install_root}/nifi-${version}"
  $nifi_properties_file = "${software_directory}/conf/nifi.properties"

  $zookeeper_client_port = 2181
  $zookeeper_state_directory = "${var_directory}/state/zookeeper"
  $zookeeper_connect_string = $cluster_nodes.map |$key, $value| {
    "${key}:${zookeeper_client_port}"
  }.sort.join(',')

  $cluster_properties = {
    'nifi.cluster.protocol.is.secure'                     => 'true',
    'nifi.cluster.is.node'                                => 'true',
    'nifi.cluster.node.address'                           => $cluster_node_address,
    'nifi.cluster.node.protocol.port'                     => $cluster_node_protocol_port,

    'nifi.zookeeper.connect.string'                       => $zookeeper_connect_string,
    'nifi.state.management.embedded.zookeeper.start'      => 'true',
    'nifi.state.management.embedded.zookeeper.properties' => "${config_directory}/zookeeper.properties",
    'nifi.state.management.provider.cluster'              => 'zk-provider'
  }

  $standalone_properties = {
    'nifi.cluster.is.node' => 'false',
    'nifi.cluster.node.address' => '',
    'nifi.cluster.node.protocol.port' => '',
    'nifi.zookeeper.connect_string' => '',
    'nifi.state.management.embedded.zookeeper.start' => 'false',
    'nifi.state.management.provider.local' => 'local-provider'
  }

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

  if $cluster {
    $_nifi_properties = $path_properties + $cluster_properties + $nifi_properties
  }
  else {
    $_nifi_properties = $path_properties + $standalone_properties + $nifi_properties
  }

  $_nifi_properties.each |String $key, Nifi::Property $value| {
    ini_setting { "nifi property ${key}":
      ensure  => present,
      path    => $nifi_properties_file,
      setting => $key,
      value   => $value,
    }
  }

  $authorizers_properties = {
    'cluster' =>  $cluster,
    'cluster_nodes' => $cluster_nodes,
    'config_directory' => $config_directory,
    'initial_admin_identity' => $initial_admin_identity,
  }

  file { "${config_directory}/authorizers.xml":
    ensure  => file,
    content => epp('nifi/authorizers.xml.epp', $authorizers_properties),
    owner   => 'root',
    group   => $group,
    mode    => '0640',
  }

  $state_management_properties = {
    'local_directory' => "${var_directory}/state/local",
    'zookeeper_connect_string' => $zookeeper_connect_string,
  }

  file { "${config_directory}/state-management.xml":
    ensure  => file,
    content => epp('nifi/state-management.xml.epp', $state_management_properties),
    owner   => 'root',
    group   => $group,
    mode    => '0640',
  }

  $zookeeper_properties = {
    'state_directory' => $zookeeper_state_directory,
    'cluster_nodes' => $cluster_nodes,
  }

  file { "${var_directory}/state":
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  if $cluster {
    file { "${config_directory}/zookeeper.properties":
      ensure  => file,
      content => epp('nifi/zookeeper.properties.epp', $zookeeper_properties),
      owner   => 'root',
      group   => $group,
      mode    => '0640',
    }
    file { $zookeeper_state_directory:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }

    $zookeeper_node_id = $cluster_nodes[$cluster_node_address]['id']
    file { "${zookeeper_state_directory}/myid":
      ensure  => file,
      content => "${zookeeper_node_id}\n",
      owner   => $user,
      group   => $group,
      mode    => '0640',
    }
  }
}
