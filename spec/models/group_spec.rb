# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Group Model' do
  it 'has a valid factory' do
    expect(create(:group)).to be_valid
  end

  it 'is invalid without a name' do
    expect { create(:group, name: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testgroup_admin = create(:group, name: 'admin')
    _testgroup_reseller = create(:group, name: 'reseller')
    _testgroup_user = create(:group, name: 'user')
    expect(Group.count).to eq(3)
  end

  it 'serializes to valid json' do
    testgroup = create(:group)
    expect { JSON.parse(testgroup.to_json) }.not_to raise_exception
  end
end
