require 'spec_helper'

describe 'nifi' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node) { 'node1.example.com' }

      context 'with cluster => false' do
        let(:params) { { cluster: false } }

        it { is_expected.to compile }
      end

      context 'with cluster => true' do
        let(:params) {
          {
            cluster: true,
            cluster_nodes: {
              'node1.example.com': { id: 1 },
              'node2.example.com': { id: 2 },
              'node3.example.com': { id: 3 },
            }
          }
        }

        it { is_expected.to compile }
      end
    end
  end
end
