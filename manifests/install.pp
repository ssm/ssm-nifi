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
  String $user,
  String $group,
) {

  $local_tarball = "${download_tmp_dir}/nifi-${version}.tar.gz"
  $software_directory = "${install_root}/nifi-${version}"

  archive { $local_tarball:
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
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  file { $log_directory:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  file { $var_directory:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  file { "${install_root}/current":
    ensure => link,
    target => $software_directory,
  }
}
