# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe DkimPolicy do
  subject { described_class.new(user, dkim) }

  let(:dkim) do
    FactoryGirl.create(:dkim)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_dkims) }
    let(:dkim) { user.domains.dkims.first }
    let(:otheruser) { create(:user_with_domains) }

    it { should permit(:create) }

    context 'assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:dkim, domain_id: otheruser.domains.first.id)
      end
      it { should_not permit_args(:update_with, params) }
      it { should_not permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:dkim, id: dkim.id, domain_id: user.domains.first.id)
      end
      it { should permit(:update) }
      it { should permit_args(:update_with, params) }
    end

    it { should permit(:show) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_dkims) }
    let(:user) { create(:user) }
    let(:dkim) { owner.domains.dkims.first }

    it { should permit(:create) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_dkims) }
    let(:owner) { user.customers.first }
    let(:dkim) { owner.domains.dkims.first }

    it { should permit(:create) }
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'changing the id as an unauthorized user' do
    let(:user) { create(:user_with_dkims) }
    let(:dkim) { user.domains.first.dkims.first }
    let(:params) { attributes_for(:dkim, id: 1234) }

    it { should_not permit_args(:update_with, params) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_dkims) }
    let(:user) { create(:reseller) }
    let(:dkim) { owner.customers.first.domains.dkims.first }

    it { should permit(:create) }
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
