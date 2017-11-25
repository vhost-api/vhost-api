# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe DomainPolicy do
  subject { described_class.new(user, domain) }

  let(:domain) do
    FactoryGirl.create(:domain)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_domains) }
    let(:domain) { user.domains.first }
    let(:otheruser) { create(:user) }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) { create(:user_with_domains_and_exhausted_domain_quota) }
      let(:domain) { user.domains.first }

      it { is_expected.not_to permit(:create) }
    end

    context 'assigning to another user' do
      let(:params) { attributes_for(:domain, user_id: otheruser.id) }

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) { attributes_for(:domain, id: domain.id, user_id: user.id) }

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'changing the id as an unauthorized user' do
    let(:user) { create(:user_with_domains) }
    let(:domain) { user.domains.first }
    let(:params) { attributes_for(:domain, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_domains) }
    let(:user) { create(:user) }
    let(:domain) { owner.domains.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:user_with_domains_and_exhausted_domain_quota) }
      let(:user) { create(:user_with_exhausted_domain_quota) }
      let(:domain) { owner.domains.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_domains) }
    let(:owner) { user.customers.first }
    let(:domain) { owner.domains.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_domains_and_exhausted_domain_quota)
      end
      let(:owner) { user.customers.first }
      let(:domain) { owner.domains.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_domains) }
    let(:user) { create(:reseller) }
    let(:domain) { owner.customers.first.domains.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_domains) }
      let(:user) { create(:reseller_with_exhausted_domain_quota) }
      let(:domain) { owner.domains.first }

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
