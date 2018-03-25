# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength
describe ApikeyPolicy do
  subject { described_class.new(user, apikey) }

  let(:apikey) do
    FactoryBot.create(:apikey)
  end

  context 'when being the owner' do
    let(:user) { create(:user_with_apikeys) }
    let(:apikey) { user.apikeys.first }
    let(:otheruser) { create(:user) }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:user) { create(:user_with_apikeys_and_exhausted_apikey_quota) }
      let(:apikey) { user.apikeys.first }

      it { is_expected.not_to permit(:create) }
    end

    context 'when assigning to another user' do
      let(:params) { attributes_for(:apikey, user_id: otheruser.id) }

      it { is_expected.not_to permit_args(:update_with, params) }
      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when changing attributes w/o changing the owner' do
      let(:params) { attributes_for(:apikey, id: apikey.id, user_id: user.id) }

      it { is_expected.to permit(:update) }
      it { is_expected.to permit_args(:update_with, params) }
    end

    it { is_expected.to permit(:show) }
    it { is_expected.to permit(:destroy) }
  end

  context 'when changing the id as an unauthorized user' do
    let(:user) { create(:user_with_apikeys) }
    let(:apikey) { user.apikeys.first }
    let(:params) { attributes_for(:apikey, id: 1234) }

    it { is_expected.not_to permit_args(:update_with, params) }
  end

  context 'when being another unprivileged user' do
    let(:owner) { create(:user_with_apikeys) }
    let(:user) { create(:user) }
    let(:apikey) { owner.apikeys.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:owner) { create(:user_with_apikeys_and_exhausted_apikey_quota) }
      let(:user) { create(:user_with_exhausted_apikey_quota) }
      let(:apikey) { owner.apikeys.first }

      it { is_expected.not_to permit(:create) }
    end

    it { is_expected.not_to permit(:show) }
    it { is_expected.not_to permit(:update) }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being the reseller of the user' do
    let(:user) { create(:reseller_with_customers_and_apikeys) }
    let(:owner) { user.customers.first }
    let(:apikey) { owner.apikeys.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
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

  context 'when being another unprivileged reseller' do
    let(:owner) { create(:reseller_with_customers_and_apikeys) }
    let(:user) { create(:reseller) }
    let(:apikey) { owner.customers.first.apikeys.first }

    context 'when with available quota' do
      it { is_expected.to permit(:create) }
    end

    context 'when with exhausted quota' do
      let(:owner) { create(:reseller_with_customers_and_apikeys) }
      let(:user) { create(:reseller_with_exhausted_apikey_quota) }
      let(:apikey) { owner.apikeys.first }

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
# rubocop:enable Metrics/BlockLength
