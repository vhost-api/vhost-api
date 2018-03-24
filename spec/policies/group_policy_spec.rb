# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

describe GroupPolicy do
  subject { described_class.new(user, group) }

  let(:group) { FactoryGirl.create(:group, name: 'testgroup') }

  context 'with a user' do
    let(:user) { FactoryGirl.create(:user) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'with a reseller' do
    let(:user) { FactoryGirl.create(:reseller) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'with an admin' do
    let(:user) { FactoryGirl.create(:admin) }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end
end
