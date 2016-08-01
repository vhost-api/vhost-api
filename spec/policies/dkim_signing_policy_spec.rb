# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe DkimSigningPolicy do
  subject { described_class.new(user, dkimsigning) }

  let(:dkimsigning) do
    FactoryGirl.create(:dkimsigning)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_dkimsignings) }
    let(:dkimsigning) { user.domains.first.dkims.first.dkim_signings.first }
    let(:otheruser) { create(:user_with_dkims) }

    it { should permit(:create) }

    context 'assigning to another unauthorized domain' do
      let(:params) do
        attributes_for(:dkimsigning,
                       dkim_id: otheruser.domains.first.dkims.first.id)
      end
      it { should_not permit_args(:update_with, params) }
      it { should_not permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) do
        attributes_for(:dkimsigning,
                       dkim_id: user.domains.first.dkims.first.id)
      end
      it { should permit(:update) }
      it { should permit_args(:update_with, params) }
    end

    it { should permit(:show) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_dkimsignings) }
    let(:user) { create(:user) }
    let(:dkimsigning) { owner.domains.first.dkims.first.dkim_signings.first }

    it { should permit(:create) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_dkimsignings) }
    let(:owner) { user.customers.first }
    let(:dkimsigning) { owner.domains.first.dkims.first.dkim_signings.first }

    it { should permit(:create) }
    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_dkimsignings) }
    let(:user) { create(:reseller) }
    let(:dkimsigning) do
      owner.customers.first.domains.first.dkims.first.dkim_signings.first
    end

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
