require 'spec_helper_acceptance'

pp_defaults = <<-PUPPETCODE
  class { 'java': }
  class { 'nifi': }

  Package['java'] -> Service['nifi.service']
PUPPETCODE

describe 'Apache NiFi' do
  idempotent_apply(pp_defaults)

  describe file('/opt/nifi') do
    it { is_expected.to be_directory }
  end

  describe file('/opt/nifi/current/conf/nifi.properties') do
    it { is_expected.to be_file }
  end

  describe service('nifi.service') do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe file('/var/log/nifi') do
    it { is_expected.to be_directory }
  end

  describe file('/var/log/nifi/nifi-bootstrap.log') do
    it { is_expected.to be_file }
  end
end
