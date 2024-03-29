# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

### [0.10.0] - 2022-10-25

- Install NiFi version 1.18.0 by default.

## [0.9.0] - 2022-10-11

### Changed

- Install NiFi version 1.17.0 by default.
- This module now downloads NiFi as a "zip" archive instead of "tar.gz", and
  requires the "unzip" package to be present.
- Declare support for Red Hat Enterprise Linux 9
- Declare support for Ubuntu 22.04 LTS (Jammy Jellyfish)

### Fixed

- Cluster: When parameter `cluster` is set to true, ensure that the nifi
  property `nifi.authorizer.configuration.file` points to the configuration
  file installed by this module to authorize cluster nodes. (Note: See
  README / Limitations about clustering and authentication)

## [0.8.0] - 2020-01-21

### Added

- Add `zookeeper_*` class parameters. These are used for clustering NiFi using
  the embedded zookeeper.

### Changed

- Permit `Sensitive[String]` as NiFi property values.

## [0.7.2] - 2022-01-19

### Changed

- Install NiFi version 1.15.3 by default

## [0.7.1] - 2022-01-19

### Fixed

- Update missing [REFERENCE](REFERENCE.md) for [0.7.0] changes
- Update the `puppet/systemd` module in documentation and test fixtures

## [0.7.0] - 2022-01-18

### Changed

- Install NiFi version 1.15.2 by default
- Data type Validation of NiFi properties. Valid keys are `String`, and values
  must be of type `Boolean`, `Integer` or `String`.

### Added

- Manage a log directory `/var/log/nifi` configurable with the `log_directory`
  parameter.
- Manage a configuration directory `/opt/nifi/config` configuable with the
  `config_directory` parameter. This is used for configuration files intended
  to survive an upgrade of NiFi.
- Manage state management configuration file `state-management.xml` in the
  `config_directory`.  See [README](README.md) to use your own state management
  configuration.
- Manage authorizations configuration file `authorizers.xml` in the
  `config_directory` to add cluster nodes and optionally an initial admin
  identity.  See [README](README.md) for how to use your own authorization
  configuration.
- Manage a NiFi cluster with the `cluster` and `cluster_nodes` parameters. This
  enables the built-in zookeeper for cluster state management as well as
  authorization for cluster nodes. NiFi clustering with this module assumes you
  have a source of TLS keys, certificates and CA trust. See [README](README.md) for
  configuring a cluster.

## [0.6.0] - 2021-12-20

### Changed

- Install NiFi version `1.15.1` by default

## [0.5.0] - 2021-08-09

### Changed

- Install NiFi version `1.14.0` by default

## [0.4.0]

### Fixed

- Use user and group parameters when managing the install directory instead of hardcoded 'nifi'
- Fix missing parameter `var_directory`

### Changed

- Install NiFi version `1.13.2` by default.
- Update module with PDK 2.1.0
- Adjust upper bounds for dependencies on puppet and modules
- Improve documentation example for basic usage

### Added

- Add documentation example for NiFi cluster

## [0.3.1] - 2020-07-09

### Fixed

- Fix syntax error in module metadata ([#5])

## [0.3.0] - 2020-03-17

### Added

- Add acceptance testing

### Changed

- Install NiFi version `1.11.3` by default.
- Set NiFi local state directory to `${var_directory}/state/local` to
  ensure it survives future NiFi upgrades. To avoid losing state when
  upgrading to this module version, stop the NiFi service, move
  `/opt/nifi/nifi-${version}/state/local` to
  `/var/opt/nifi/state/local`, then run Puppet to configure NiFi.

## [0.2.0] - 2020-02-22

### Added

- Management of `nifi.properties`

### Changed

- Default nifi version to install is now `1.11.1`.

## [0.1.1] - 2020-01-22

### Changed

- systemd now starts the process as a simple instead of a forking
  service.

## [0.1.0] - 2020-01-14

### Added

- Initial release.
- Download, install and start Apache NiFi.

[unreleased]: https://github.com/ssm/ssm-nifi/compare/0.9.0...main
[0.9.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.9.0
[0.8.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.8.0
[0.7.2]: https://github.com/ssm/ssm-nifi/releases/tag/0.7.2
[0.7.1]: https://github.com/ssm/ssm-nifi/releases/tag/0.7.1
[0.7.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.7.0
[0.6.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.6.0
[0.5.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.5.0
[0.4.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.4.0
[0.3.1]: https://github.com/ssm/ssm-nifi/releases/tag/0.3.1
[0.3.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.3.0
[0.2.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.2.0
[0.1.1]: https://github.com/ssm/ssm-nifi/releases/tag/0.1.1
[0.1.0]: https://github.com/ssm/ssm-nifi/releases/tag/0.1.0

[#5]: https://github.com/ssm/ssm-nifi/pull/5
