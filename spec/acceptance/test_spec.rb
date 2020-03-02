require 'spec_helper_acceptance'

describe 'install' do
  let(:pp) do
    <<-MANIFEST
    class { 'nifi':
    }
    MANIFEST
  end

  it 'applies the manifest twice with no stderr' do
    idempotent_apply(pp)
  end
end
