require 'spec_helper'

describe 'nifi::config' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          install_root: '/opt/nifi',
          var_directory: '/var/opt/nifi',
          nifi_properties: {},
          user: 'nifi',
          group: 'nifi',
        }
      end

      it { is_expected.to compile }
    end
  end
end
