# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe UserPolicy do
  subject { described_class.new(user, testuser) }

  let(:testuser) do
    FactoryGirl.create(:user, name: 'Testuser', login: 'testuser')
  end

  context 'for the user itself' do
    let(:user) { testuser }

    it { should permit(:show) }
    it { should_not permit(:create) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'changing the id as an unauthorized user' do
    let(:user) { create(:reseller_with_customers) }
    let(:testuser) { user.customers.first }
    let(:params) { attributes_for(:user, id: 1234) }

    it { should_not permit_args(:update_with, params) }
  end

  context 'for another unprivileged user' do
    let(:owner) { create(:user_with_domains) }
    let(:user) { create(:user_with_domains) }
    let(:domain) { owner.domains.first }

    it { should_not permit(:create) }
    it { should_not permit(:show) }
    it { should_not permit(:update) }
    it { should_not permit(:destroy) }
  end

  context 'for the reseller of the user' do
    let(:user) do
      reseller = create(:reseller_with_customers)
      package = create(:reseller_package)
      reseller.packages << package
      reseller.save
      reseller
    end
    let(:testuser) { user.customers.first }
    let(:group) { testuser.group }

    context 'assigning 1 package' do
      let(:params) do
        packages = create_list(:package, 2, user_id: user.id)
        attrs = attributes_for(:user, reseller_id: user.id, group_id: group.id)
        attrs[:packages] = [packages.first]
        attrs
      end

      context 'with available quota' do
        it { should permit(:create) }
        it { should permit_args(:create_with, params) }
      end
    end

    context 'assigning 3 packages' do
      let(:testuser) do
        testuser = user.customers.first
        packages = create_list(:package, 2, user_id: user.id)
        testuser.packages = packages
        testuser.save
        testuser
      end
      let(:params) do
        packages = create_list(:package, 3, user_id: user.id)
        attrs = attributes_for(:user, reseller_id: user.id, group_id: group.id)
        attrs[:packages] = packages
        attrs
      end

      context 'with available quota' do
        it { should permit(:create) }
        it { should permit_args(:create_with, params) }
      end
    end

    context 'with exhausted quota' do
      let(:user) { create(:reseller_with_exhausted_customer_quota) }

      it { should_not permit(:create) }
    end

    it { should permit(:show) }
    it { should permit(:update) }
    it { should permit(:destroy) }
  end

  context 'for another unprivileged reseller' do
    let(:owner) { create(:reseller, name: 'Reseller', login: 'reseller') }
    let(:user) { create(:reseller, name: 'Reseller2', login: 'reseller2') }
    let(:testuser) do
      create(:user,
             name: 'Customer',
             login: 'customer',
             reseller_id: owner.id)
    end

    context 'with available quota' do
      it { should permit(:create) }
    end

    context 'with exhausted quota' do
      let(:user) { create(:reseller_with_exhausted_customer_quota) }

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
