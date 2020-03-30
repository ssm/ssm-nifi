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

NiFi requires Java Runtime Environment. Nifi 1.10.1 runs on Java 8 or
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

Follow the NiFi administration guide for configuration.

## Usage

To download and install NiFi, include the module. This will download
nifi, unpack it under `/opt/nifi/nifi-<version>`, and start the
service with default configuration and storage locations.

```puppet
include nifi
```

To host the file locally, add a nifi::download_url variable for the
module.

```yaml
nifi::download_url: "https://repo.example.com/nifi/nifi-1.10.0-bin.tar.gz"
```

Please keep `nifi::download_url`, `nifi::download_checksum` and
`nifi::version` in sync. The URL, checksum and version should match.
Otherwise, Puppet will become confused.

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
    }
  }

  # DIY part. You can use one of:
  # - just a static file
  # - template with data from hiera
  # - puppetlabs-concat with exported concat::fragments from your nodes
  # - augeas XML lens
  # - something else
  # see authorizers.xml for suggested contents below.
  file { '/opt/nifi/current/conf/authorizers.xml':
    notify  => Service['nifi.service'],
    content => epp('profile/nifi/authorizers.xml.epp', { 'foo' => 'bar' } )
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

#### Authorization rules

Provision a `/opt/nifi/current/conf/authorizers.xml` configuration
files to your NiFi nodes

This file adds the certificates of the cluster nodes, as well as the
certificate for the initial admin. Once the initial admin logs in,
they can manage users and roles in the web interface.


```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!--
    This file lists the userGroupProviders, accessPolicyProviders, and authorizers to use when running securely. In order
    to use a specific authorizer it must be configured here and it's identifier must be specified in the nifi.properties file.
    If the authorizer is a managedAuthorizer, it may need to be configured with an accessPolicyProvider and an userGroupProvider.
    This file allows for configuration of them, but they must be configured in order:

    ...
    all userGroupProviders
    all accessPolicyProviders
    all Authorizers
    ...
-->
<authorizers>

    <userGroupProvider>
        <identifier>file-user-group-provider</identifier>
        <class>org.apache.nifi.authorization.FileUserGroupProvider</class>
        <property name="Users File">./conf/users.xml</property>
        <property name="Legacy Authorized Users File"></property>

        <property name="Initial User Identity 1">CN=nifi-admin.users.example.com</property>
        <property name="Node identity 1">CN=nifi-01.example.com</property>
        <property name="Node identity 2">CN=nifi-02.example.com</property>
    </userGroupProvider>

    <accessPolicyProvider>
        <identifier>file-access-policy-provider</identifier>
        <class>org.apache.nifi.authorization.FileAccessPolicyProvider</class>
        <property name="User Group Provider">file-user-group-provider</property>
        <property name="Authorizations File">./conf/authorizations.xml</property>
        <property name="Initial Admin Identity">CN=nifi-admin.users.example.com</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Node identity 1">CN=nifi-01.example.com</property>
        <property name="Node identity 1">CN=nifi-02.example.com</property>
        <property name="Node Group"></property>
    </accessPolicyProvider>

    <authorizer>
        <identifier>managed-authorizer</identifier>
        <class>org.apache.nifi.authorization.StandardManagedAuthorizer</class>
        <property name="Access Policy Provider">file-access-policy-provider</property>
    </authorizer>
</authorizers>
```


## Limitations

This module is under development, and therefore somewhat light on
functionality.

Configuration outside `nifi.properties` are not managed yet. These can
be managed outside the module with `file` resources.

## Development

In the Development section, tell other users the ground rules for
contributing to your project and how they should submit their work.
