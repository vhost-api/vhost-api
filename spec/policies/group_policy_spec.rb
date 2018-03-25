# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

describe GroupPolicy do
  subject { described_class.new(user, group) }

  let(:group) { FactoryBot.create(:group, name: 'testgroup') }

  context 'with a user' do
    let(:user) { FactoryBot.create(:user) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'with a reseller' do
    let(:user) { FactoryBot.create(:reseller) }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'with an admin' do
    let(:user) { FactoryBot.create(:admin) }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end
end
