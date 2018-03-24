# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe 'VHost-API MailAccount Model' do
  it 'has a valid factory' do
    expect(create(:mailaccount)).to be_valid
  end

  it 'is invalid without an email' do
    expect { create(:mailaccount, email: nil) }.to(
      raise_exception(DataMapper::SaveFailureError)
    )
  end

  it 'allows adding records' do
    _testmailaccount1 = create(:mailaccount)
    _testmailaccount2 = create(:mailaccount)
    expect(MailAccount.count).to eq(2)
  end

  it 'allows adding accounts with multiple aliases/sources' do
    _testmailaccount = create(:mailaccount_with_aliases_and_sources)
    expect(MailAccount.count).to eq(1)
  end

  it 'serializes to valid json' do
    testmailaccount = build(:mailaccount)
    expect { JSON.parse(testmailaccount.to_json) }.not_to raise_exception
  end

  it 'returns the owner as a User object' do
    _testadmin = create(:admin)
    test = create(:mailaccount)
    expect(test.owner).to be_an_instance_of(User)
  end

  it 'returns quotausage in Bytes' do
    testmailaccount = create(:mailaccount)
    email = testmailaccount.email.split('@')[0]
    domain = testmailaccount.email.split('@')[1]
    quotafile_name = "testdata/vmail/#{domain}/#{email}/.quotausage"

    allow(testmailaccount).to receive(:quotafile).and_return(quotafile_name)
    allow(File).to receive(:exist?).with(quotafile_name).and_return(true)
    allow(IO).to receive(:read).with(quotafile_name).and_return(
      "priv/quota/messages\n932\npriv/quota/storage\n67664\n"
    )

    expect(testmailaccount.quotausage).to eq(67_664)
  end

  it 'returns quotausage_rel in Percent' do
    testmailaccount = create(:mailaccount)
    email = testmailaccount.email.split('@')[0]
    domain = testmailaccount.email.split('@')[1]
    quotafile_name = "testdata/vmail/#{domain}/#{email}/.quotausage"

    allow(testmailaccount).to receive(:quotafile).and_return(quotafile_name)
    allow(File).to receive(:exist?).with(quotafile_name).and_return(true)
    allow(IO).to receive(:read).with(quotafile_name).and_return(
      "priv/quota/messages\n932\npriv/quota/storage\n67664\n"
    )

    expect(testmailaccount.quotausage_rel).to eq(
      (67_664 * 100 / testmailaccount.quota).round(1)
    )
  end

  it 'returns sieveusage in Bytes' do
    testmailaccount = create(:mailaccount)
    email = testmailaccount.email.split('@')[0]
    domain = testmailaccount.email.split('@')[1]
    sievefile_name = "testdata/vmail/#{domain}/#{email}/dovecot.sieve"

    allow(testmailaccount).to receive(:sievefile).and_return(sievefile_name)
    allow(File).to receive(:exist?).with(sievefile_name).and_return(true)
    allow(File).to receive(:size).with(sievefile_name).and_return(13_728)

    expect(testmailaccount.sieveusage).to eq(13_728)
  end

  it 'returns sieveusage_rel in Percent' do
    testmailaccount = create(:mailaccount)
    email = testmailaccount.email.split('@')[0]
    domain = testmailaccount.email.split('@')[1]
    sievefile_name = "testdata/vmail/#{domain}/#{email}/dovecot.sieve"

    allow(testmailaccount).to receive(:sievefile).and_return(sievefile_name)
    allow(File).to receive(:exist?).with(sievefile_name).and_return(true)
    allow(File).to receive(:size).with(sievefile_name).and_return(13_728)

    expect(testmailaccount.sieveusage_rel).to eq(
      (13_728 * 100 / testmailaccount.quota_sieve_script).round(1)
    )
  end
end
# rubocop:enable Metrics/BlockLength
