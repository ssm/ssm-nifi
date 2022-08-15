# @summary Install Apache NiFi
#
# Private subclass for installing Apache NiFi.
#
# @api private
class nifi::install (
  Stdlib::Absolutepath $install_root,
  String $version,
  String $download_url,
  String $download_checksum,
  String $download_checksum_type,
  Stdlib::Absolutepath $download_tmp_dir,
  Stdlib::Absolutepath $var_directory,
  Stdlib::Absolutepath $log_directory,
  Stdlib::Absolutepath $config_directory,
  String $user,
  String $group,
  Enum['zip','tar.gz'] $download_archive_type = 'zip',
) {
  $local_archive_file = "${download_tmp_dir}/nifi-${version}.${download_archive_type}"
  $software_directory = "${install_root}/nifi-${version}"

  $default_directory_parameters = {
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  archive { $local_archive_file:
    source        => $download_url,
    checksum      => $download_checksum,
    checksum_type => $download_checksum_type,
    extract       => true,
    extract_path  => $install_root,
    creates       => $software_directory,
    cleanup       => true,
    user          => $user,
    group         => $group,
  }

  user { $user:
    system => true,
    gid    => $group,
    home   => $install_root,
  }

  group { $group:
    system => true,
  }

  file { $install_root:
    * => $default_directory_parameters,
  }

  file { $config_directory:
    * => $default_directory_parameters,
  }

  file { $log_directory:
    * => $default_directory_parameters,
  }

  file { $var_directory:
    * => $default_directory_parameters,
  }

  file { "${install_root}/current":
    ensure => link,
    target => $software_directory,
  }
}
