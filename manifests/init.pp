# @summary Manage Apache NiFi
#
# Install, configure and run Apache NiFi
#
# @param version
#   The version of Apache NiFi. This must match the version in the
#   tarball. This is used for managing files, directories and paths in
#   the service.
#
# @param user
#   The user owning the nifi installation files, and running the
#   service.
#
# @param group
#   The group owning the nifi installation files, and running the
#   service.
#
# @param download_url
#   Where to download the binary installation tarball from.
#
# @param download_checksum
#   The expected checksum of the downloaded tarball. This is used for
#   verifying the integrity of the downloaded tarball.
#
# @param download_checksum_type
#   The checksum type of the downloaded tarball. This is used for
#   verifying the integrity of the downloaded tarball.
#
# @param download_tmp_dir
#   Temporary directory for downloading the tarball.
#
# @param service_limit_nofile
#   The limit on number of open files permitted for the service. Used
#   for LimitNOFILE= in nifi.service.
#
# @param service_limit_nproc
#   The limit on number of processes permitted for the service. Used
#   for LimitNPROC= in nifi.service.
#
# @param install_root
#   The root directory of the nifi installation.
#
# @param var_directory
#   The root of the writable paths used by NiFi. Nifi will create
#   directories beneath this path.  This will implicitly add nifi
#   properties for working directories and repositories.
#
# @param log_directory
#   The directory where NiFi stores its user, app and bootstrap logs. Nifi will
#   create log files beneath this path and take care of log rotation and
#   deletion.
#
# @param config_directory
#   Directory for NiFi version independent configuration files to be kept
#   across NiFi version upgrades. This is used in addition to the "./conf"
#   directory within each NiFi installation.
#
# @param nifi_properties
#   Hash of parameter key/values to be added to conf/nifi.properties.
#
# @param cluster
#   If true, enables the built-in zookeeper cluster for shared configuration
#   and state management. The cluster_nodes parameter is used to configure the
#   zookeeper cluster, and nifi will connect to their local zookeper instance.
#
# @param cluster_nodes
#   A hash of zookeeper cluster nodes and their ID. The ID must be an integer
#   between 1 and 255, unique in the cluster, and must not be changed once set.
#
#  The hash must be structured like { 'fqdn.example.com' => { 'id' => 1 },... }
#
# @example Defaults
#   include nifi
#
# @example Downloading from a different repository
#   class { 'nifi':
#     version           => 'x.y.z',
#     download_url      => 'https://my.local.repo.example.com/apache/nifi/nifi-x.y.z.tar.gz',
#     download_checksum => 'abcde...',
#   }
#
# @example Configuring a NiFi cluster
#   class { 'nifi':
#     cluster       => true,
#     cluster_nodes => {
#       'nifi-1.example.com' => { 'id' => 1 },
#       'nifi-2.example.com' => { 'id' => 2 },
#       'nifi-3.example.com' => { 'id' => 3 },
#     }
#   }
#
class nifi (
  String $version = '1.15.3',
  String $download_url = "https://dlcdn.apache.org/nifi/${version}/nifi-${version}-bin.tar.gz",
  String $download_checksum = 'c77fe8e4bc534f16fd5482832285e0bde07495308f31fd6d0fbb3118042daed4',
  String $download_checksum_type = 'sha256',
  Stdlib::Absolutepath $download_tmp_dir = '/var/tmp',
  String $user = 'nifi',
  String $group = 'nifi',
  Integer $service_limit_nofile = 50000,
  Integer $service_limit_nproc = 10000,
  Hash[String,Variant[String,Integer,Boolean]] $nifi_properties = {},
  Stdlib::Absolutepath $install_root = '/opt/nifi',
  Stdlib::Absolutepath $var_directory = '/var/opt/nifi',
  Stdlib::Absolutepath $log_directory = '/var/log/nifi',
  Stdlib::Absolutepath $config_directory = '/opt/nifi/config',
  Boolean $cluster = false,
  Hash[
    Stdlib::Fqdn, Struct[{id => Integer[1,255]}]
  ] $cluster_nodes = {},
  Optional[String] $initial_admin_identity = undef,
) {

  class { 'nifi::install':
    install_root           => $install_root,
    version                => $version,
    user                   => $user,
    group                  => $group,
    download_url           => $download_url,
    download_checksum      => $download_checksum,
    download_checksum_type => $download_checksum_type,
    download_tmp_dir       => $download_tmp_dir,
    config_directory       => $config_directory,
    var_directory          => $var_directory,
    log_directory          => $log_directory,
  }

  class { 'nifi::config':
    install_root     => $install_root,
    user             => $user,
    group            => $group,
    config_directory => $config_directory,
    var_directory    => $var_directory,
    nifi_properties  => $nifi_properties,
    version          => $version,
    cluster          => $cluster,
    cluster_nodes    => $cluster_nodes,
  }

  class {'nifi::service':
    install_root  => $install_root,
    version       => $version,
    user          => $user,
    limit_nofile  => $service_limit_nofile,
    limit_nproc   => $service_limit_nproc,
    log_directory => $log_directory,
  }

  Class['nifi::install'] -> Class['nifi::config'] ~> Class['nifi::service']
}
