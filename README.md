# Puppet module ssm-nifi

- [Puppet module ssm-nifi](#puppet-module-ssm-nifi)
  - [Description](#description)
  - [Setup](#setup)
    - [What nifi affects](#what-nifi-affects)
    - [Setup Requirements](#setup-requirements)
    - [Beginning with nifi](#beginning-with-nifi)
  - [Usage](#usage)
    - [Using a specific version of NiFi](#using-a-specific-version-of-nifi)
    - [Hosting NiFi on a local repository](#hosting-nifi-on-a-local-repository)
    - [Example: Configuring TLS](#example-configuring-tls)
    - [Clustering NiFi](#clustering-nifi)
    - [NiFi user authentication](#nifi-user-authentication)
    - [NiFi user authorization](#nifi-user-authorization)
    - [Managing upgrades](#managing-upgrades)
    - [Managing logs](#managing-logs)
    - [NiFi state management](#nifi-state-management)
  - [Notes and thoughts](#notes-and-thoughts)
  - [Limitations](#limitations)
  - [Development](#development)

## Description

Install and configure the [Apache NiFi](https://nifi.apache.org/)
dataflow automation software.

## Setup

### What nifi affects

This module will download the Apache NiFi tarball to `/var/tmp/`.
Please make sure you have space for this file.

The tarball will be unpacked to a subdirectory under `/opt/nifi` by default,
where it will require about the same disk space. For ease of access, the
symlink `/opt/nifi/current` will point to the managed nifi directory.

NiFi defaults to store logs and state and configuration within the installation
directory. This module changes this behaviour.

The module will create `/var/opt/nifi`, for persistent storage outside
the software install root. This will also configure the following nifi
properties to create directories under this path.

- nifi.content.repository.directory.default
- nifi.database.directory
- nifi.documentation.working.directory
- nifi.flowfile.repository.directory
- nifi.nar.working.directory
- nifi.provenance.repository.directory.default
- nifi.web.jetty.working.directory

The module will create `/var/log/nifi`, and configures NiFi to write log files
to this directory. NiFi handles log rotation by itself. See [Managing
logs](#managing-logs) for more information.

The module will create `/opt/nifi/conf` to store puppet managed configuration
files. The NiFi generated configuration files and the `flow.xml` configuration
archive will also be stored here.

### Setup Requirements

NiFi requires Java Runtime Environment. NiFi 1.14.0 runs on Java 8 or
Java 11.

NiFi requires ~ 1.3 GiB download, temporary storage and unpacked
storage. Ensure `/opt/nifi` and `/var/tmp` has room for the downloaded
and unpacked software.

When installing on local infrastructure, consider download the
distribution tarballs, validate them with the Apache distribution
keys, and store it on a local repository. Adjust the configuration
variables to point to your local repository. The [NiFi download
page](https://nifi.apache.org/download.html) also documents how to
verify the integrity and authenticity of the downloaded files.

### Beginning with nifi

Add dependency modules to your puppet environment:

- puppet/archive
- puppet/systemd
- puppetlabs/inifile
- puppetlabs/stdlib

You need to ensure java 8 or 11 is installed. If in doubt, use this module:

- puppetlabs/java

By default, NiFi 1.14.0 and later starts with a self-signed TLS certificate,
listens on the `lo` interface only, and generates a random username and
password for access. You will need to add nifi properties to override this.
Follow the NiFi administration guide for configuration, or see the example
further down in this README.

## Usage

To download and install NiFi, include the module. This will download nifi,
unpack it under `/opt/nifi/nifi-<version>`, and start the service with default
configuration and storage locations.

By default, NiFi is not available over the network. It will bind to `127.0.0.1`
port `8443`, using HTTPS with a self signed certificate. To make NiFi available
over the network, you will need to ensure it listens on an external interface.
Set the property `nifi.web.https.host` to a hostname or an external IP address.
To change the port number, set `nifi.web.https.port`.

A minimal manifest for installing Java and NiFi, then making NiFi available
over the network is:

```puppet
class { 'java': }
class { 'nifi':
  nifi_properties => {
    'nifi.web.https.host' => $trusted['certname'],
  }
}

Class['java'] -> Class['nifi::service']
```

### Using a specific version of NiFi

This module installs a specific version of NiFi. If a newer version of NiFi has
been released available, the older one will generally not be downloadable from
the Apache download CDN site. You will need to adjust the module parameters
`version` and `download_checksum`:

```puppet
class { 'nifi':
  version           => 'x.y.z',
  download_checksum => 'abcde...' # sha256 checksum
}
```

The SHA256 checksum of the NiFi tar.gz is available on the [NiFi download
page](https://nifi.apache.org/download.html).

### Hosting NiFi on a local repository

NiFi is a big download. Please consider hosting a copy locally for your own
use. To use a local repository, set the `download_url`, `download_checksum` and
`version` parameters.

Example using puppet manifests:

```puppet
class { 'nifi':
  version           => '1.14.0',
  download_checksum => '858e12bce1da9bef24edbff8d3369f466dd0c48a4f9892d4eb3478f896f3e68b',
  download_url      => 'https://repo.example.com/nifi/nifi-1.14.0-bin.tar.gz',
}
```

Example using hieradata:

```puppet
include nifi
```

```yaml
nifi::version: "1.14.0"
nifi::download_checksum: "858e12bce1da9bef24edbff8d3369f466dd0c48a4f9892d4eb3478f896f3e68b"
nifi::download_url: "https://repo.example.com/nifi/nifi-1.14.0-bin.tar.gz"
```

Please keep `download_url`, `download_checksum` and `version` in sync. The
URL, checksum and version should match. Otherwise, Puppet will become
confused.

To set nifi properties, like the 'sensitive properties key', add them
to the `nifi_properties` class parameter. Example:

```puppet
class { 'nifi':
  nifi_properties => {
    'nifi.sensitive.props.key' =>  'keep it secret, keep it safe',
  },
}
```

(I recommend you use `hiera-eyaml` to store this somewhat securely.)

### Example: Configuring TLS

NiFi will generate a self-signed TLS certificate by default.

To use a trusted TLS certificate is outside the scope of this module, a good
place for it is in a "profile" wrapping the nifi module with other bits and
pieces.

This example is based on the PKI configuration paths on the Red Hat OS family.
It assumes you have certificates and keys stored under `/etc/pki/tls`, and use
the system CA trust store under `/etc/pki/ca-trust`.

The `puppetlabs-java_ks` is used to manage the Java keystore file used by NiFi.

```puppet
class profile::nifi (
  Stdlib::Fqdn $hostname = $trusted['certname'],
  Sensitive[String] $keystorepassword = 'changeme',
) {

  $hostcert    = "/etc/pki/tls/certs/${hostname}.pem"
  $hostprivkey = "/etc/pki/tls/private/${hostname}.pem"

  class { 'java':
    package => 'java-11-openjdk-headless',
    before  => Class['nifi::service'],
  }

  class { 'nifi':
    nifi_properties => {

      # Web properties
      'nifi.web.https.host'            => $hostname,

      # TLS properties
      # - Key store generated in this profile
      'nifi.security.keystore'         => '/opt/nifi/config/kesystore.jks',
      'nifi.security.keystoreType'     => 'jks',
      'nifi.security.keystorePasswd'   => $keystorepassword,

      # - Default system trust store path and password for Java on Red Hat
      'nifi.security.truststore'       => '/etc/pki/ca-trust/extracted/java/cacerts',
      'nifi.security.truststoreType'   => 'jks',
      'nifi.security.truststorePasswd' => 'changeit',
    }
  }

  java_ks { "${hostname}:/opt/nifi/config/keystore.jks":
    ensure      => latest,
    password    => $keystorepassword,
    certificate => $hostcert,
    private_key => $hostprivkey,
    require     => Class['nifi::config'],
    before      => Class['nifi::service'],
  }
}
```

### Clustering NiFi

Warning: Using this module for nifi clusters is not yet stable. Configuration
file overrides is currently required, and your NiFi configuration may break on
upgrades of this module.

To create a cluster, set the `cluster` class parameter to true, and add cluster
members to the `cluster_nodes` hash. This configures the cluster to use
zookeeper for shared state.

Nifi requires you to set `nifi.sensitive.props.key` to the same string on all
cluster nodes.

If you cluster nifi and also override the `authorizers.xml` file, ensure you
also include the cluster nodes in this file.

Also, you need to configure TLS:

- Generate TLS certificates
- Set the property `nifi.cluster.protocol.is.secure = true`

Or continue without TLS:

- Set the property `nifi.web.http.port`

```puppet
class profile::nifi {
  class { 'java':
    package => 'java-11-openjdk-headless',
    before  => Class['nifi::service']
  }

  class { 'nifi':
    cluster         => true,
    nifi_properties => {
      'nifi.sensitive.props.key' => 'a shared secret for encrypting properties',
    },
    cluster_nodes   => {
      'node1.example.com' => { 'id' => 1 },
      'node2.example.com' => { 'id' => 2 },
      'node3.example.com' => { 'id' => 3 },
    }
  }
}
```

In addition to the clustering parameters, add certificates using the [TLS
example in this readme](#example-configuring-tls) from a trusted Certificate
Authority for cluster communication.

### NiFi user authentication

User authentication is managed using the
`nifi.login.identity.providers.configuration.file` and
`nifi.security.user.login.identity.provider` properties. On a fresh install,
NiFi uses the `single-user-provider`. A random username and password is created
and written to the `nifi-app.log` file. This is documented at
<https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#user_authentication>

This module does not manage login identity provider configuration. If you want
to connect your NiFi to Active Directory or other LDAP server, you need to
manage this property and provide a file.

```puppet
class profile::nifi {
  $login_identity_providers => '/opt/nifi/conf/custom-login-identity-providers.xml'

  class nifi {
    nifi_properties => {
      nifi.login.identity.providers.configuration.file => $login_identity_providers,
      nifi.security.user.login.identity.provider       => 'my-custom-identity-provider',
    }
  }

  $template_params = {
    # [...]
  }
  file { $login_identity_providers:
    content => epp('profile/nifi/my-custom-login-identity-providers.epp, $template_params')
    # [...]
  }
}
```

### NiFi user authorization

Authorization is managed using the `nifi.authorizer.configuration.file` and
`nifi.security.user.authorizer` properties. This is documented at
'https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#multi-tenant-authorization'

This module manages `/opt/nifi/conf/authorizers.xml` to support clustering, it
is otherwise similar to the default content.

You can override this file using a collector (using the `File <| ... |> {}`
syntax) to use your own template by overriding the `content` parameter of the
file managed by the nifi module.

```puppet
class profile::nifi {
  $authorizers => '/opt/nifi/conf/authorizers.xml'

  class { 'nifi':
    nifi_properties => {
      nifi.authorizer.configuration.file => $authorizers, # module default, added for clarity
      nifi.security.user.authorizer      => 'my-custom-authorizer-provider',
    }
  }

  $template_params = {
    # [...]
  }
  File <| title == $authorizers |> {
    content => epp('profile/nifi/my-custom-authorizers.epp, $template_params')
  }
}
```

Note: The example above assumes that the module parameter
`nifi::config_directory` is left at its default `/opt/nifi/conf`.

### Managing upgrades

The [Upgrade
Recommendations](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#upgrade-recommendations)
lists properties which should be set to enable NiFi upgrades to keep
the same configuration and state.

The module has defaults for data storage outside the installation
directory. For now, you need to add add settings to point to the
`config_resource_dir` used in the examples above.

- `nifi.flow.configuration.file`
- `nifi.flow.configuration.archive.dir`
- `nifi.authorizer.configuration.file`

### Managing logs

The NiFi logs are written to `$nifi::log_directory` (default `/var/log/nifi`).
The directory prevents access for "other", but the files within are otherwise
readable. You can use ACLs on the directory to permit access to your favourite
log reading program. The
[puppet-posix\_acl](https://forge.puppet.com/modules/puppet/posix_acl) module
can be used like this:

```puppet
class profile::nifi (
  $log_directory => '/var/log/nifi',
) {

  class { 'nifi':
    log_directory => $log_directory,
    # [...]
  }

  posix_acl { $log_directory:
    action     => set,
    permission => [ 'user:logreader:r-x' ],
    require    => File[$log_directory],
  }
}
```

### NiFi state management

This module configures NiFi to use `/opt/nifi/conf/state-management.xml`
instead of the `./conf/state-management.xml` in the NiFi install directory. The
values in this file are NiFi defaults, apart from the local state management
directory or the cluster state management connect string.

To override this file with your own values, provide a `nifi_properties` class
parameter which includes `nifi.state.management.configuration.file` pointing to
your own file.

```puppet
class profile::nifi (
  $custom_state_management => '/path/to/custom/state-management.xml',
) {

  class { 'nifi':
    nifi_properties => {
      'nifi.state.management.configuration.file' => $custom_state_management
    }
  }

  file { $custom_state_management:
    notify => Class['nifi::service'],
  }
}
```

## Notes and thoughts

About the ZooKeeper connection string. The [NiFi administration guide] says "This should containe a list of all ZooKeeper instances in the ZooKeeper quorum", while the [ZooKeeper overview] says "a client connects to one node". This module follows assumes that the NiFi cluster runs its own ZooKeeper and lets any node connect as client to any other node.

```pre
  nifi 1          nifi 2          nifi 3
    |               |               |
zookeeper 1 --- zookeeper 2 --- zookeeper 3
```

Java Keystore: [NiFi administration guide] says "JKS is the preferred type",
while the "keytool" utility provided by the java package says "JKS is
deprecated, use PKCS12".

[NiFi administration guide]: https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html
[ZooKeeper overview]: https://zookeeper.apache.org/doc/current/zookeeperOver.html

## Limitations

This module is under development, and therefore somewhat light on functionality
and sensible defaults.

State management: This module configures rudimentary NiFi state management for
local state and with zookeeper for cluster state. The `redis` method is not
managed with this module.

Cluster configuration breaks authorization: Enabling clustering with this
module using `cluster => true` will break the default user authorization. You
will have to override this file to add your preferred method. See examples
above.

To manage more configuration files, add a file resource of your own, and set
the related property using the `nifi_properties` class parameter.

## Development

In the Development section, tell other users the ground rules for
contributing to your project and how they should submit their work.
