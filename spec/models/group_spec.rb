# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Group Model' do
  it 'has a valid factory' do
    expect(create(:admin_group)).to be_valid
    expect(create(:reseller_group)).to be_valid
    expect(create(:user_group)).to be_valid
  end

  it 'is invalid without a name' do
    expect { create(:admin_group, name: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
    expect { create(:reseller_group, name: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
    expect { create(:user_group, name: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testgroup_admin = create(:admin_group)
    _testgroup_reseller = create(:reseller_group)
    _testgroup_user = create(:user_group)
    expect(Group.count).to eq(3)
  end

  it 'serializes to valid json' do
    testgroup_admin = build(:admin_group)
    testgroup_reseller = build(:reseller_group)
    testgroup_user = build(:user_group)
    expect { JSON.parse(testgroup_admin.to_json) }.not_to raise_exception
    expect { JSON.parse(testgroup_reseller.to_json) }.not_to raise_exception
    expect { JSON.parse(testgroup_user.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    testadmin = create(:admin)
    testgroup = create(:user_group)
    expect(testgroup.owner).to be_an_instance_of(User)
    expect(testgroup.owner).to eq(testadmin)
  end
end
