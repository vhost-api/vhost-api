# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe ApikeyPolicy do
  subject { described_class.new(user, apikey) }

  let(:apikey) do
    FactoryGirl.create(:apikey)
  end

  context 'for the owner' do
    let(:user) { create(:user_with_apikeys) }
    let(:apikey) { user.apikeys.first }
    let(:otheruser) { create(:user) }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) { create(:user_with_apikeys_and_exhausted_apikey_quota) }
      let(:apikey) { user.apikeys.first }

      it { is_expected.not_to permit(:create) }
    end

    context 'assigning to another user' do
      let(:params) { attributes_for(:apikey, user_id: otheruser.id) }

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'changing attributes w/o changing the owner' do
      let(:params) { attributes_for(:apikey, id: apikey.id, user_id: user.id) }

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'changing the id as an unauthorized user' do
    let(:user) { create(:user_with_apikeys) }
    let(:apikey) { user.apikeys.first }
    let(:params) { attributes_for(:apikey, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_apikeys) }
    let(:user) { create(:user) }
    let(:apikey) { owner.apikeys.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:user_with_apikeys_and_exhausted_apikey_quota) }
      let(:user) { create(:user_with_exhausted_apikey_quota) }
      let(:apikey) { owner.apikeys.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_apikeys) }
    let(:owner) { user.customers.first }
    let(:apikey) { owner.apikeys.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) do
        create(:reseller_with_customers_and_apikeys_and_exhausted_apikey_quota)
      end
      let(:owner) { user.customers.first }
      let(:apikey) { owner.apikeys.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:update) }
    it { is_expected.to permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_apikeys) }
    let(:user) { create(:reseller) }
    let(:apikey) { owner.customers.first.apikeys.first }

    context 'with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_apikeys) }
      let(:user) { create(:reseller_with_exhausted_apikey_quota) }
      let(:apikey) { owner.apikeys.first }

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