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
        let(:params) do
          {
            cluster: true,
            cluster_nodes: {
              'node1.example.com': { id: 1 },
              'node2.example.com': { id: 2 },
              'node3.example.com': { id: 3 },
            },
            nifi_properties: {
              'test.boolean': true,
              'test.integer': 42,
              'test.string': 'I like words',
              'test.sensitive': sensitive('I like sensitive words'),
            },
          }
        end

        it { is_expected.to compile }
      end
    end
  end
end
