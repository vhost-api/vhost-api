# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Vhost Model' do
  it 'has a valid factory' do
    expect(create(:vhost)).to be_valid
  end

  it 'is invalid without a fqdn' do
    expect { create(:vhost, fqdn: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testvhost = create(:vhost)
    expect(Vhost.count).to eq(1)
  end

  it 'serializes to valid json' do
    testvhost = build(:vhost)
    expect { JSON.parse(testvhost.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testvhost = create(:vhost)
    expect(testvhost.owner).to be_an_instance_of(User)
  end
end
