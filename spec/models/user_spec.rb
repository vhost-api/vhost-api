# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe 'VHost-API User Model' do
  # rubocop:disable RSpec/MultipleExpectations
  it 'has a valid factory' do
    admin_group = create(:group, name: 'admin')
    expect(create(:admin, group: admin_group)).to be_valid
    expect(create(:reseller)).to be_valid
    expect(create(:user)).to be_valid
  end

  it 'is invalid without a login' do
    expect { create(:admin, login: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
    expect { create(:reseller, login: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
    expect { create(:user, login: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testadmin = create(:admin)
    _testreseller1 = create(:reseller)
    _testreseller2 = create(:reseller)
    _testuser1 = create(:user)
    _testuser2 = create(:user)
    _testuser3 = create(:user)
    # 6 + 1 user for the packages (auto created)
    expect(User.count).to eq(7)
  end

  it 'allows authentication with a given password' do
    password = 'test1234!'
    testuser = build(:user, password: password)
    expect(testuser.authenticate(password)).to be_truthy
  end

  it 'serializes to valid json' do
    testadmin = build(:admin)
    testreseller = build(:reseller)
    testuser = build(:user)
    expect { JSON.parse(testadmin.to_json) }.not_to raise_exception
    expect { JSON.parse(testreseller.to_json) }.not_to raise_exception
    expect { JSON.parse(testuser.to_json) }.not_to raise_exception
  end

  it 'checks ownership of a given object against itself' do
    testadmin = create(:admin)
    testuser = create(:user)
    expect(testadmin.be_owner_of(testuser)).to be_truthy
    expect(testuser.be_owner_of(testadmin)).not_to be_truthy
  end

  it 'allows checking of admin privileges' do
    testadmin = build(:admin)
    testreseller = build(:reseller)
    testuser = build(:user)
    expect(testadmin.be_admin).to be_truthy
    expect(testreseller.be_admin).not_to be_truthy
    expect(testuser.be_admin).not_to be_truthy
  end

  it 'allows checking of reseller privileges' do
    testreseller = build(:reseller)
    testuser = build(:user)
    expect(testreseller.be_reseller).to be_truthy
    expect(testuser.be_reseller).not_to be_truthy
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testuser = create(:user)
    expect(testuser.owner).to be_an_instance_of(User)
  end
  # rubocop:enable RSpec/MultipleExpectations
end
# rubocop:enable Metrics/BlockLength
