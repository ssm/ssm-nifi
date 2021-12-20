# nifi

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with nifi](#setup)
    * [What nifi affects](#what-nifi-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with nifi](#beginning-with-nifi)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

Install and configure the [Apache NiFi](https://nifi.apache.org/)
dataflow automation software.

## Setup

### What nifi affects

This module will download the Apache NiFi tarball to `/var/tmp/`.
Please make sure you have space for this file.

The tarball will be unpacked to `/opt/nifi` by default, where it will
require about the same disk space.

The module will create `/var/opt/nifi`, for persistent storage outside
the software install root. This will also configure the following nifi
properties to create directories under this path.

* nifi.content.repository.directory.default
* nifi.database.directory
* nifi.documentation.working.directory
* nifi.flowfile.repository.directory
* nifi.nar.working.directory
* nifi.provenance.repository.directory.default
* nifi.web.jetty.working.directory

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

* camptocamp/systemd
* puppet/archive
* puppetlabs/inifile
* puppetlabs/stdlib

You need to ensure java 8 or 11 is installed. If in doubt, use this module:

* puppetlabs/java

By default, NiFi 1.14.0 and later starts with a self-signed TLS certificate,
listens on the `lo` interface only, and generates a random username and
password for access. You will need to add nifi properties to override this.
Follow the NiFi administration guide for configuration, or see the example
further down in this README.

## Usage

To download and install NiFi, include the module. This will download
nifi, unpack it under `/opt/nifi/nifi-<version>`, and start the
service with default configuration and storage locations.

```puppet
include nifi
```

To host a specific version of nifi locally, use the `download_url`,
`download_checksum` and `version` parameters.

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

### Using the Puppet CA for TLS

NiFi can use TLS certificates for authentication between nodes and for
users. While NiFi provides a CA in the `nifi-toolkit` package, we can
use the Puppet CA for this.

Managing this is on the roadmap for this module. For now, this can be
handled in the profile which loads the nifi class.

#### Dependencies

Add the `puppetlabs-java_ks` module to your environment to manage the
Java keystore and truststore used by NiFi.

#### Profile

Make a nifi profile, which glues everything toghether.

In this example the TLS key and certificate are class parameters. You
can use Hiera for this, but I encourage you to make a fact for this.
It will be useful for all other managed infrastructure that uses TLS,
like metrics and logging.

```puppet
class profile::nifi (
  $version,
  $checksum,
  $toolkit_checksum,
  Stdlib::Absolutepath $truststore = '/var/opt/nifi/nifi.ts',
  Stdlib::Absolutepath $keystore = '/var/opt/nifi/nifi.ks',
  Stdlib::Absolutepath $hostprivkey = '/var/lib/puppet/ssl/private_keys/nifi-01.example.com.pem',
  Stdlib::Absolutepath $hostcert = '/var/lib/puppet/ssl/certs/nifi-01.example.com.pem',
  Stdlib::Absolutepath $localcacert = '/var/lib/puppet/ssl/certs/ca.pem',
  Stdlib::Absolutepath $config_resource_dir = '/opt/nifi/config-resources',
  String $storepassword = 'puppet',
) {

  $url = "http://mirrors.ibiblio.org/apache/nifi/${version}/nifi-${version}-bin.tar.gz"
  $toolkit_url = "http://mirrors.ibiblio.org/apache/nifi/${version}/nifi-toolkit-${version}-bin.tar.gz"

  class { 'java': }
  class { 'nifi':
    download_checksum => $checksum,
    download_url      => $url,
    version           => $version,
    nifi_properties => {

      # Site to Site properties
      'nifi.remote.input.host'          => $trusted['certname'],
      'nifi.remote.input.secure'        => 'true',
      'nifi.remote.input.socket.port'   => '10443',

      # Web properties
      'nifi.web.https.host'             => $trusted['certname'],
      'nifi.web.https.port'             => '9443',
      'nifi.web.http.port'              => '',

      # Security properties
      'nifi.security.keystore'          => $keystore,
      'nifi.security.keystorePasswd'    => $storepassword,
      'nifi.security.keystoreType'      => 'jks',
      'nifi.security.truststore'        => $truststore,
      'nifi.security.truststorePasswd'  => $storepassword,
      'nifi.security.truststoreType'    => 'jks',
      'nifi.cluster.protocol.is.secure' => 'true',

      # Host properties
      'nifi.cluster.node.address'       => $trusted['certname'],
      'nifi.cluster.node.protocol.port' => '11443',

      # Path properties
      'nifi.authorizer.configuration.file'  => "${config_resource_dir}/authorizers.xml",
      'nifi.flow.configuration.file'        => "${config_resource_dir}/flow.xml.gz",
      'nifi.flow.configuration.archive.dir' => "${config_resource_dir}/archive",

    }
  }

  class { 'nifi_toolkit':
    download_url      => $toolkit_url,
    download_checksum => $toolkit_checksum,
    version           => $version,
  }

  Package['java'] -> Service['nifi.service']

  Java_ks {
    ensure   => latest,
    password => $storepassword,
    require  => Class['nifi::config'],
    before   => Class['nifi::service'],
  }

  java_ks { 'nifi:truststore':
    target       => $truststore,
    certificate  => $localcacert,
    trustcacerts => true,
  }

  java_ks { 'nifi:keystore':
    target      => $keystore,
    certificate => $hostcert,
    private_key => $hostprivkey,
  }
}
```

As soon as this is active, nifi will listens on TLS on port 9443, and
anonymous access to NiFi is disabled. You will need to generate a key
on the puppet master for your initial administrative user.

#### Generate a user certificate

Generate a certificate to use from your web browser.

The name of this certificate will be added to the authorization file.

```
[root@puppet ~]# puppetserver ca generate --certname nifi-admin.users.example.com
```

Note that puppetserver has limitations on what the certificate name
can contain. If you make it look like a hostname, it will work. If you
make it look like an email address, it will not.

Create a PKCS12 bundle from the key and certificate, download it to
your workstation, and add it to your web browser.

#### Clustering NiFi

Creating a NiFi cluster requires authorization rules for cluster nodes
and zookeeper configuration.

#### Authorizers

Provision a `/opt/nifi/current/conf/authorizers.xml` configuration
files to your NiFi nodes

This file adds the certificates of the cluster nodes, as well as the
certificate for the initial admin. Once the initial admin logs in,
they can manage users and roles in the web interface.

If this is created from a template, it needs the `admin_identity`,
`node identities` and path to the `config_resource_dir` used above.

Example authorization configuration rules using TLS certificates for
cluster nodes and admin web access:

The path to `authorizers.xml` is configured with the
nifi.authorizer.configuration.file property. Default is
`./conf/authorizers.xml`, but it should be set outside the
installation directory to make upgrades easier.

```puppet
file { '/opt/nifi/config-resources/authorizers.xml':
  content => epp('profile/nifi/authorizers.xml.epp', {
    'admin_identity'      => $admin_identity,
    'cluster_nodes'       => $cluster_nodes,
    'config_resource_dir' => $config_resource_dir,
  }),
}
```

```puppet
<%- | String $admin_identity,
      Hash[Stdlib::Fqdn, Struct[{id => Integer[1]}]] $cluster_nodes,
      Stdlib::Absolutepath $config_resource_dir,
    | -%>
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!--

    This file is managed by puppet.

-->
<authorizers>
    <authorizer>
      <identifier>file-provider</identifier>
      <class>org.apache.nifi.authorization.FileAuthorizer</class>
      <property name="Authorizations File"><%= $config_resource_dir %>/authorizations.xml</property>
      <property name="Users File"><%= $config_resource_dir %>/users.xml</property>
      <property name="Legacy Authorized Users File"></property>

      <property name="Initial Admin Identity"><%= $admin_identity %></property>

      <%- $cluster_nodes.each | $cluster_node, $params | {
            $node_dn = "CN=${cluster_node}"
            $node_id = "Node Identity ${params['id']}"
      -%>
      <property name="<%= $node_id %>"><%= $node_dn %></property>
      <%- } -%>
    </authorizer>
</authorizers>
```

In a three node cluster it should look like:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!--

    This file is managed by puppet.

-->
<authorizers>
    <authorizer>
      <identifier>file-provider</identifier>
      <class>org.apache.nifi.authorization.FileAuthorizer</class>
      <property name="Authorizations File">/opt/nifi/config-resources/authorizations.xml</property>
      <property name="Users File">/opt/nifi/config-resources/users.xml</property>
      <property name="Legacy Authorized Users File"></property>

      <property name="Initial Admin Identity">CN=admin.users.example.com</property>

      <property name="Node Identity 1">CN=node1.example.com</property>
      <property name="Node Identity 2">CN=node2.example.com</property>
      <property name="Node Identity 3">CN=node3.example.com</property>
    </authorizer>
</authorizers>
```
#### Zookeeper

The `./conf/zookeeper.properties` file is used in a multi node cluster

In a three-node cluster it should look like:

```ini
# Managed by Puppet

initLimit=10
autopurge.purgeInterval=24
syncLimit=5
tickTime=2000
dataDir=/var/opt/nifi/state/zookeeper
autopurge.snapRetainCount=30

server.1=node1.example.com:2888:3888;2181
server.2=node2.example.com:2888:3888;2181
server.3=node3.example.com:2888:3888;2181
```

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

## Limitations

This module is under development, and therefore somewhat light on
functionality.

Configuration outside `nifi.properties` are not managed yet. These can
be managed outside the module with `file` resources.

This module configures rudimentart NiFi state management with local
file method. The `zookeeper` and `redis` methods are not managed with
this module.

## Development

In the Development section, tell other users the ground rules for
contributing to your project and how they should submit their work.
