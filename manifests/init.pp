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
# @param nifi_properties
#   Hash of parameter key/values to be added to conf/nifi.properties.
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
class nifi (
  String $version = '1.11.3',
  String $download_url = 'http://mirrors.ibiblio.org/apache/nifi/1.11.3/nifi-1.11.3-bin.tar.gz',
  String $download_checksum = '8b7fc8e8a6e2af7f7a37212fabbd11664ecd935dd3158e9fc3349f93929fb210',
  Stdlib::Absolutepath $download_tmp_dir = '/var/tmp',
  String $user = 'nifi',
  String $group = 'nifi',
  String $download_checksum_type = 'sha256',
  Integer $service_limit_nofile = 50000,
  Integer $service_limit_nproc = 10000,
  Hash $nifi_properties = {},
  Stdlib::Absolutepath $install_root = '/opt/nifi',
  Stdlib::Absolutepath $var_directory = '/var/opt/nifi',
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
  }

  class { 'nifi::config':
    install_root    => $install_root,
    user            => $user,
    group           => $group,
    var_directory   => $var_directory,
    nifi_properties => $nifi_properties,
    version         => $version,
  }

  class {'nifi::service':
    install_root => $install_root,
    version      => $version,
    user         => $user,
    limit_nofile => $service_limit_nofile,
    limit_nproc  => $service_limit_nproc,
  }

  Class['nifi::install'] -> Class['nifi::config'] ~> Class['nifi::service']
}
