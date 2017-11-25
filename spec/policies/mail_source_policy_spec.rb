# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe MailSourcePolicy do
  subject { described_class.new(user, mailsource) }

  let(:mailsource) do
    FactoryGirl.create(:mailsource)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_mailsources) }
    let(:mailsource) { user.domains.mail_sources.first }
    let(:otheruser) { create(:user_with_domains) }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:user_with_mailsources_and_exhausted_mailsource_quota)
      end
      let(:mailsource) { user.domains.mail_sources.first }

      it { is_expected.not_to permit(:create) }
    end

    context 'assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:mailsource, domain_id: otheruser.domains.first.id)
      end

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:mailsource,
                       id: mailsource.id,
                       domain_id: user.domains.first.id)
      end

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'changing the id as an unauthorized user' do
    let(:user) { create(:user_with_mailsources) }
    let(:mailsource) { user.domains.first.mail_sources.first }
    let(:params) { attributes_for(:mailsource, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_mailsources) }
    let(:user) { create(:user) }
    let(:mailsource) { owner.domains.mail_sources.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) do
        create(:user_with_mailsources_and_exhausted_mailsource_quota)
      end
      let(:user) { create(:user_with_exhausted_mailsource_quota) }
      let(:mailsource) { owner.domains.mail_sources.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_mailsources) }
    let(:owner) { user.customers.first }
    let(:mailsource) { owner.domains.mail_sources.first }
    let(:mailaccount) { owner.domains.mail_accounts.first }
    let(:params) do
      attributes_for(:mailsource,
                     domain_id: owner.domains.first.id,
                     src: [mailaccount.id])
    end

    it { is_expected.to permit_args(:create_with, params) }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_mailsources_and_exhausted_quota)
      end

      let(:owner) { user.customers.first }
      let(:mailsource) { owner.domains.mail_sources.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_mailsources) }
    let(:user) { create(:reseller) }
    let(:mailsource) { owner.customers.first.domains.mail_sources.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_mailsources) }
      let(:user) { create(:reseller_with_exhausted_mailsource_quota) }
      let(:mailsource) { owner.domains.mail_sources.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:create) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end
end
