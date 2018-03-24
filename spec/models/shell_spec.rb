# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

describe 'VHost-API Shell Model' do
  it 'has a valid factory' do
    expect(create(:shell)).to be_valid
  end

  it 'is invalid without a shell' do
    expect { create(:shell, shell: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testshell = create(:shell)
    expect(Shell.count).to eq(1)
  end

  it 'serializes to valid json' do
    testshell = build(:shell)
    expect { JSON.parse(testshell.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    testshell = create(:shell)
    expect(testshell.owner).to be_an_instance_of(User)
  end
end
