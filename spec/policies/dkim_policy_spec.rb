# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe DkimPolicy do
  subject { described_class.new(user, dkim) }

  let(:dkim) do
    FactoryGirl.create(:dkim)
  end

  context 'when being the owner' do
    let(:user) { create(:user_with_dkims) }
    let(:dkim) { user.domains.dkims.first }
    let(:otheruser) { create(:user_with_domains) }

    it { is_expected.to permit(:create) }

    context 'when assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:dkim, domain_id: otheruser.domains.first.id)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:dkim, id: dkim.id, domain_id: user.domains.first.id)
      end

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when being another unprivileged user' do
    let(:owner) { create(:user_with_dkims) }
    let(:user) { create(:user) }
    let(:dkim) { owner.domains.dkims.first }

    it { is_expected.to permit(:create) }
    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_dkims) }
    let(:owner) { user.customers.first }
    let(:dkim) { owner.domains.dkims.first }

    it { is_expected.to permit(:create) }
    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when changing the id as an unauthorized user' do
    let(:user) { create(:user_with_dkims) }
    let(:dkim) { user.domains.first.dkims.first }
    let(:params) { attributes_for(:dkim, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'when being another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_dkims) }
    let(:user) { create(:reseller) }
    let(:dkim) { owner.customers.first.domains.dkims.first }

    it { is_expected.to permit(:create) }
    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:create) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end
end
# rubocop:enable Metrics/BlockLength
