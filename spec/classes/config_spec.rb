require 'spec_helper'

describe 'nifi::config' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          install_root: '/opt/nifi',
          version: '1.2.3',
          config_directory: '/opt/nifi/config',
          var_directory: '/var/opt/nifi',
          user: 'nifi',
          group: 'nifi',
          nifi_properties: {
            'test.foo.bar' => 'thud grunt',
          },
        }
      end

      it { is_expected.to compile }

      # Implicit property from var_directory
      it {
        is_expected.to contain_ini_setting('nifi property nifi.flowfile.repository.directory')
          .with_path('/opt/nifi/nifi-1.2.3/conf/nifi.properties')
          .with_setting('nifi.flowfile.repository.directory')
          .with_value('/var/opt/nifi/flowfile_repository')
      }

      # Explicit property
      it {
        is_expected.to contain_ini_setting('nifi property test.foo.bar')
          .with_path('/opt/nifi/nifi-1.2.3/conf/nifi.properties')
          .with_setting('test.foo.bar')
          .with_value('thud grunt')
      }
    end
  end
end
