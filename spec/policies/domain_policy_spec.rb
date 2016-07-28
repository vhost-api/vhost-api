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

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) { create(:user_with_domains_and_exhausted_domain_quota) }
      let(:domain) { user.domains.first }

      it { should_not permit(:create) }
    end

    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_domains) }
    let(:user) { create(:user) }
    let(:domain) { owner.domains.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:user_with_domains_and_exhausted_domain_quota) }
      let(:user) { create(:user_with_exhausted_domain_quota) }
      let(:domain) { owner.domains.first }

      it { should_not permit(:create) }
    end

    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_domains) }
    let(:owner) { user.customers.first }
    let(:domain) { owner.domains.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_domains_and_exhausted_domain_quota)
      end
      let(:owner) { user.customers.first }
      let(:domain) { owner.domains.first }

      it { should_not permit(:create) }
    end

    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_domains) }
    let(:user) { create(:reseller) }
    let(:domain) { owner.customers.first.domains.first }

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_domains) }
      let(:user) { create(:reseller_with_exhausted_domain_quota) }
      let(:domain) { owner.domains.first }

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
