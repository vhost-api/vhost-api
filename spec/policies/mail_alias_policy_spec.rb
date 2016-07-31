# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe MailAliasPolicy do
  subject { described_class.new(user, mailalias) }

  let(:mailalias) do
    FactoryGirl.create(:mailalias)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_mailaliases) }
    let(:mailalias) { user.domains.mail_aliases.first }
    let(:otheruser) { create(:user_with_domains) }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:user_with_mailaliases_and_exhausted_mailalias_quota)
      end
      let(:mailalias) { user.domains.mail_aliases.first }

      it { should_not permit(:create) }
    end

    context 'assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:mailalias, domain_id: otheruser.domains.first.id)
      end
      it { should_not permit_args(:update_with, params) }
      it { should_not permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:mailalias, domain_id: user.domains.first.id)
      end
      it { should permit(:update) }
      it { should permit_args(:update_with, params) }
    end

    it { should permit(:show) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_mailaliases) }
    let(:user) { create(:user) }
    let(:mailalias) { owner.domains.mail_aliases.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) do
        create(:user_with_mailaliases_and_exhausted_mailalias_quota)
      end
      let(:user) { create(:user_with_exhausted_mailalias_quota) }
      let(:mailalias) { owner.domains.mail_aliases.first }

      it { should_not permit(:create) }
    end

    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_mailaliases) }
    let(:owner) { user.customers.first }
    let(:mailalias) { owner.domains.mail_aliases.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_mailaliases_and_exhausted_quota)
      end

      let(:owner) { user.customers.first }
      let(:mailalias) { owner.domains.mail_aliases.first }

      it { should_not permit(:create) }
    end

    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_mailaliases) }
    let(:user) { create(:reseller) }
    let(:mailalias) { owner.customers.first.domains.mail_aliases.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_mailaliases) }
      let(:user) { create(:reseller_with_exhausted_mailalias_quota) }
      let(:mailalias) { owner.domains.mail_aliases.first }

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
