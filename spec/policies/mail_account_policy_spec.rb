# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe MailAccountPolicy do
  subject { described_class.new(user, mailaccount) }

  let(:mailaccount) do
    FactoryGirl.create(:mailaccount)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_mailaccounts) }
    let(:mailaccount) { user.domains.mail_accounts.first }
    let(:otheruser) { create(:user_with_domains) }

    context 'with available quota' do
      context 'CREATE allocation request smaller than remaining quota' do
        it { should permit(:create) }
      end

      context 'UPDATE allocation request smaller than remaining quota' do
        let(:params) do
          policy = Pundit.policy(user, mailaccount)
          available = mailaccount.quota + policy.storage_remaining
          attributes_for(:mailaccount,
                         domain_id: user.domains.first.id,
                         quota: available)
        end

        it { should permit_args(:update_with, params) }
      end
    end

    context 'CREATE allocation request exceeding remaining quota' do
      let(:params) do
        attributes_for(:mailaccount,
                       domain_id: user.domains.first.id,
                       quota: Pundit.policy(
                         user, MailAccount
                       ).storage_remaining + 1)
      end

      it { should_not permit_args(:create_with, params) }
    end

    context 'UPDATE allocation request exceeding remaining quota' do
      let(:params) do
        policy = Pundit.policy(user, mailaccount)
        too_much = mailaccount.quota + policy.storage_remaining + 1
        attributes_for(:mailaccount,
                       domain_id: user.domains.first.id,
                       quota: too_much)
      end

      it { should_not permit_args(:update_with, params) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:user_with_mailaccounts_and_exhausted_mailaccount_quota)
      end
      let(:mailaccount) { user.domains.mail_accounts.first }

      it { should_not permit(:create) }
    end

    context 'assigning to another user' do
      let(:params) do
        attributes_for(:mailaccount, domain_id: otheruser.domains.first.id)
      end
      it { should_not permit_args(:update_with, params) }
      it { should_not permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:mailaccount, domain_id: user.domains.first.id)
      end
      it { should permit(:update) }
      it { should permit_args(:update_with, params) }
    end

    it { should permit(:show) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_mailaccounts) }
    let(:user) { create(:user) }
    let(:mailaccount) { owner.domains.mail_accounts.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) do
        create(:user_with_mailaccounts_and_exhausted_mailaccount_quota)
      end
      let(:user) { create(:user_with_exhausted_mailaccount_quota) }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { should_not permit(:create) }
    end

    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_mailaccounts) }
    let(:owner) { user.customers.first }
    let(:mailaccount) { owner.domains.mail_accounts.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_mailaccounts_and_exhausted_quota)
      end

      let(:owner) { user.customers.first }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { should_not permit(:create) }
    end

    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_mailaccounts) }
    let(:user) { create(:reseller) }
    let(:mailaccount) { owner.customers.first.domains.mail_accounts.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_mailaccounts) }
      let(:user) { create(:reseller_with_exhausted_mailaccount_quota) }
      let(:mailaccount) { owner.domains.mail_accounts.first }

      it { should_not permit(:create) }
    end

    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for an admin' do
    let(:user) { create(:admin) }

    it { should permit(:show) }
    it { should permit(:create) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end
end
