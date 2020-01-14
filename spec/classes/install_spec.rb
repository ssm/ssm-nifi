require 'spec_helper'

describe 'nifi::install' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          install_root: '/nonexistant',
          version: '1.0.0',
          download_url: 'http://localhost/nifi-1.0.0.tar.gz',
          download_checksum: 'abcde...',
          download_checksum_type: 'sha256',
          download_tmp_dir: '/var/tmp',
          user: 'nifi',
          group: 'nifi',
        }
      end

      it { is_expected.to compile }
    end
  end
end
