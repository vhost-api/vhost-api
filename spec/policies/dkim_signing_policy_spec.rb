# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe DkimSigningPolicy do
  subject { described_class.new(user, dkimsigning) }

  let(:dkimsigning) do
    FactoryBot.create(:dkimsigning)
  end

  context 'when being the owner' do
    let(:user) { create(:user_with_dkimsignings) }
    let(:dkimsigning) { user.domains.first.dkims.first.dkim_signings.first }
    let(:otheruser) { create(:user_with_dkims) }

    it { is_expected.to permit(:create) }

    context 'when assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:dkimsigning,
                       dkim_id: otheruser.domains.first.dkims.first.id)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:dkimsigning,
                       id: dkimsigning.id,
                       dkim_id: user.domains.first.dkims.first.id)
      end

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when being another unprivileged user' do
    let(:owner) { create(:user_with_dkimsignings) }
    let(:user) { create(:user) }
    let(:dkimsigning) { owner.domains.first.dkims.first.dkim_signings.first }

    it { is_expected.to permit(:create) }
    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_dkimsignings) }
    let(:owner) { user.customers.first }
    let(:dkimsigning) { owner.domains.first.dkims.first.dkim_signings.first }

    it { is_expected.to permit(:create) }
    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when changing the id as an unauthorized user' do
    let(:user) { create(:user_with_dkimsignings) }
    let(:dkimsigning) { user.domains.first.dkims.first.dkim_signings.first }
    let(:params) { attributes_for(:dkimsigning, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'when being another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_dkimsignings) }
    let(:user) { create(:reseller) }
    let(:dkimsigning) do
      owner.customers.first.domains.first.dkims.first.dkim_signings.first
    end

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
