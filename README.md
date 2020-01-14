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

- puppet/archive
- puppetlabs/stdlib
- camptocamp/systemd

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
nifi::download\_url: "http://my-local-repo.example.com/apache/nifi/1.10.0/nifi-1.10.0-bin.tar.gz"
```

Please keep `nifi::download_url`, `nifi::download_checksum` and
`nifi::version` in sync. The URL, checksum and version should match.
Otherwise, Puppet will become confused.

## Limitations

This module is under development, and therefore somewhat light on
functionality.

Configuration and repository directories are not managed yet. These
can be managed outside the module with `file` resources.

## Development

In the Development section, tell other users the ground rules for
contributing to your project and how they should submit their work.
