# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength, RSpec/NestedGroups
describe PackagePolicy do
  subject { described_class.new(user, package) }

  let(:package) { FactoryBot.create(:package, name: 'testpackage') }

  context 'when being a user' do
    let(:user) { FactoryBot.create(:user) }

    context 'when user has booked this package' do
      let(:package) { user.packages.first }

      it { is_expected.to permit(:show) }
    end

    context 'when user has not booked this package' do
      it { is_expected.not_to permit(:show) }
    end

    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when being a reseller' do
    let(:user) { FactoryBot.create(:reseller) }

    context 'when user has booked this package' do
      let(:package) { user.packages.first }

      it { is_expected.to permit(:show) }
    end

    context 'when user has not booked this package' do
      it { is_expected.not_to permit(:show) }
    end

    context 'when with remaining custom_packages quota' do
      let(:params) { attributes_for(:package, user_id: user.id) }

      it { is_expected.to permit(:create) }
      it { is_expected.to permit_args(:create_with, params) }
    end

    context 'when using an unauthorized user_id' do
      let(:otheruser) { create(:user) }
      let(:params) { attributes_for(:package, user_id: otheruser.id) }

      it { is_expected.not_to permit_args(:create_with, params) }
    end

    context 'when with exhausted custom_packages quota' do
      let(:user) { create(:reseller_with_exhausted_custom_packages_quota) }

      it { is_expected.not_to permit(:create) }
    end

    context 'when modifying their own custom packages' do
      context 'when with trying to allocate less than available quotas' do
        let(:package) { create(:package, user_id: user.id) }

        it { is_expected.to permit(:update) }
      end

      context 'when with trying to allocate more than available quotas' do
        let(:package) { create(:package, user_id: user.id) }
        let(:testcustomer) { create(:user, reseller_id: user.id) }
        let(:params) do
          available = user.packages.map(&:quota_domains).reduce(0, :+)
          attributes_for(:package,
                         user_id: user.id,
                         quota_domains: (available + 1))
        end

        before do
          testcustomer.packages = [package]
          testcustomer.save
        end

        it { is_expected.not_to permit_args(:update_with, params) }
      end

      context 'when package is used by customers' do
        let(:package) { create(:package, user_id: user.id) }
        let(:testcustomer) { create(:user, reseller_id: user.id) }
        let(:params) do
          available = user.packages.map(&:quota_domains).reduce(0, :+)
          attributes_for(:package,
                         user_id: user.id,
                         quota_domains: (available - 1))
        end

        before do
          testcustomer.packages = [package]
          testcustomer.save
        end

        it { is_expected.not_to permit(:destroy) }
        it { is_expected.to permit_args(:update_with, params) }
      end

      context 'when package is not used' do
        let(:package) { create(:package, user_id: user.id) }

        it { is_expected.to permit(:destroy) }
      end
    end

    context 'when modyfing their assigned package' do
      let(:package) { user.packages.first }

      it { is_expected.not_to permit(:update)  }
      it { is_expected.not_to permit(:destroy) }
    end
  end

  context 'when being an admin' do
    let(:user) { FactoryBot.create(:admin) }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end
end
# rubocop:enable Metrics/BlockLength, RSpec/NestedGroups
