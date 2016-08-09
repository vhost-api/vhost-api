# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API ShellUser Model' do
  it 'has a valid factory' do
    expect(create(:shelluser)).to be_valid
  end

  it 'is invalid without a login' do
    expect { create(:shelluser, username: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testshelluser1 = create(:shelluser)
    _testshelluser2 = create(:shelluser)
    _testshelluser3 = create(:shelluser)
    expect(ShellUser.count).to eq(3)
  end

  it 'serializes to valid json' do
    testshelluser = build(:shelluser)
    expect { JSON.parse(testshelluser.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testshelluser = create(:shelluser)
    expect(testshelluser.owner).to be_an_instance_of(User)
  end
end
