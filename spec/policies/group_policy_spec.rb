# frozen_string_literal: true

require File.expand_path '../../spec_helper.rb', __FILE__

describe GroupPolicy do
  subject { described_class.new(user, group) }

  let(:group) { FactoryGirl.create(:group, name: 'testgroup') }

  context 'for a user' do
    let(:user) { FactoryGirl.create(:user) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for a reseller' do
    let(:user) { FactoryGirl.create(:reseller) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'for an admin' do
    let(:user) { FactoryGirl.create(:admin) }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end
end
