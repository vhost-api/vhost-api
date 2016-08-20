# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe PackagePolicy do
  subject { described_class.new(user, package) }

  let(:package) { FactoryGirl.create(:package, name: 'testpackage') }

  context 'for a user' do
    let(:user) { FactoryGirl.create(:user) }

    context 'user has booked this package' do
      let(:package) { user.packages.first }
      it { should permit(:show) }
    end

    context 'user has not booked this package' do
      it { should_not permit(:show) }
    end

    it { should_not permit(:create)  }
    it { should_not permit(:update)  }
    it { should_not permit(:destroy) }
  end

  context 'for a reseller' do
    let(:user) { FactoryGirl.create(:reseller) }

    context 'user has booked this package' do
      let(:package) { user.packages.first }
      it { should permit(:show) }
    end

    context 'user has not booked this package' do
      it { should_not permit(:show) }
    end

    context 'with remaining custom_packages quota' do
      let(:params) { attributes_for(:package, user_id: user.id) }
      it { should permit(:create) }
      it { should permit_args(:create_with, params) }
    end

    context 'when using an unauthorized user_id' do
      let(:otheruser) { create(:user) }
      let(:params) { attributes_for(:package, user_id: otheruser.id) }
      it { should_not permit_args(:create_with, params) }
    end

    context 'with exhausted custom_packages quota' do
      let(:user) { create(:reseller_with_exhausted_custom_packages_quota) }
      it { should_not permit(:create) }
    end

    context 'modifying their own custom packages' do
      context 'with trying to allocate less than available quotas' do
        let(:package) { create(:package, user_id: user.id) }
        it { should permit(:update) }
      end

      context 'with trying to allocate more than available quotas' do
        let(:package) { create(:package, user_id: user.id) }
        let(:testcustomer) { create(:user, reseller_id: user.id) }
        before(:each) do
          testcustomer.packages = [package]
          testcustomer.save
        end
        let(:params) do
          available = user.packages.map(&:quota_domains).reduce(0, :+)
          attributes_for(:package,
                         user_id: user.id,
                         quota_domains: (available + 1))
        end
        it { should_not permit_args(:update_with, params) }
      end

      context 'package is used by customers' do
        let(:package) { create(:package, user_id: user.id) }
        let(:testcustomer) { create(:user, reseller_id: user.id) }
        before(:each) do
          testcustomer.packages = [package]
          testcustomer.save
        end
        let(:params) do
          available = user.packages.map(&:quota_domains).reduce(0, :+)
          attributes_for(:package,
                         user_id: user.id,
                         quota_domains: (available - 1))
        end
        it { should_not permit(:destroy) }
        it { should permit_args(:update_with, params) }
      end

      context 'package is not used' do
        let(:package) { create(:package, user_id: user.id) }
        it { should permit(:destroy) }
      end
    end

    context 'modyfing their assigned package' do
      let(:package) { user.packages.first }
      it { should_not permit(:update)  }
      it { should_not permit(:destroy) }
    end
  end

  context 'for an admin' do
    let(:user) { FactoryGirl.create(:admin) }

    it { should permit(:show)    }
    it { should permit(:create)  }
    it { should permit(:update)  }
    it { should permit(:destroy) }
  end
end
