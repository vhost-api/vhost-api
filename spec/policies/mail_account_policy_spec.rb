# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength, RSpec/NestedGroups
describe MailAccountPolicy do
  subject { described_class.new(user, mailaccount) }

  let(:mailaccount) do
    FactoryGirl.create(:mailaccount)
  end

  context 'when being the owner' do
    let(:user) { create(:user_with_mailaccounts) }
    let(:mailaccount) { user.domains.mail_accounts.first }
    let(:otheruser) { create(:user_with_domains) }

    context 'when with available quota' do
      context 'when CREATE allocation request smaller than remaining quota' do
        it { is_expected.to permit(:create) }
      end

      context 'when UPDATE allocation request smaller than remaining quota' do
        let(:params) do
          policy = Pundit.policy(user, mailaccount)
          available = mailaccount.quota + policy.storage_remaining
          attributes_for(:mailaccount,
                         id: mailaccount.id,
                         domain_id: user.domains.first.id,
                         quota: available)
        end

        it { is_expected.to permit_args(:update_with, params) }
      end
    end

    context 'when CREATE allocation request exceeding remaining quota' do
      let(:params) do
        attributes_for(:mailaccount,
                       domain_id: user.domains.first.id,
                       quota: Pundit.policy(
                         user, MailAccount
                       ).storage_remaining + 1)
      end

      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when UPDATE allocation request exceeding remaining quota' do
      let(:params) do
        policy = Pundit.policy(user, mailaccount)
        too_much = mailaccount.quota + policy.storage_remaining + 1
        attributes_for(:mailaccount,
                       domain_id: user.domains.first.id,
                       quota: too_much)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
    end

    context 'when with exhausted quota' do
      let(:user) do
        create(:user_with_mailaccounts_and_exhausted_mailaccount_quota)
      end
      let(:mailaccount) { user.domains.mail_accounts.first }

      it { is_expected.not_to permit(:create) }
    end

    context 'when assigning to another user' do
      let(:params) do
        attributes_for(:mailaccount, domain_id: otheruser.domains.first.id)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when changing the id as an unauthorized user' do
      let(:params) do
        attributes_for(:mailaccount,
                       id: 1234,
                       domain_id: otheruser.domains.first.id)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
    end

    context 'when changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:mailaccount, domain_id: user.domains.first.id)
      end

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when being another unprivileged user' do
    let(:owner) { create(:user_with_mailaccounts) }
    let(:user) { create(:user) }
    let(:mailaccount) { owner.domains.mail_accounts.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:owner) do
        create(:user_with_mailaccounts_and_exhausted_mailaccount_quota)
      end
      let(:user) { create(:user_with_exhausted_mailaccount_quota) }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_mailaccounts) }
    let(:owner) { user.customers.first }
    let(:mailaccount) { owner.domains.mail_accounts.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_mailaccounts_and_exhausted_quota)
      end

      let(:owner) { user.customers.first }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when being another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_mailaccounts) }
    let(:user) { create(:reseller) }
    let(:mailaccount) { owner.customers.first.domains.mail_accounts.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_mailaccounts) }
      let(:user) { create(:reseller_with_exhausted_mailaccount_quota) }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { is_expected.not_to permit(:create) }
    end

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
# rubocop:enable Metrics/BlockLength, RSpec/NestedGroups
