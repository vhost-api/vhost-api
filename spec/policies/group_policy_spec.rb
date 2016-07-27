# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe GroupPolicy do
  subject { described_class.new(user, group) }

  let(:group) { FactoryGirl.create(:group, name: 'testgroup') }

  context 'for a user' do
    let(:user) { FactoryGirl.create(:user) }

    it { should_not permit(:show)    }
    it { should_not permit(:create)  }
    it { should_not permit(:update)  }
    it { should_not permit(:destroy) }
  end

  context 'for a reseller' do
    let(:user) { FactoryGirl.create(:reseller) }

    it { should_not permit(:show)    }
    it { should_not permit(:create)  }
    it { should_not permit(:update)  }
    it { should_not permit(:destroy) }
  end

  context 'for an admin' do
    let(:user) { FactoryGirl.create(:admin) }

    it { should permit(:show)    }
    it { should permit(:create)  }
    it { should permit(:update)  }
    it { should permit(:destroy) }
  end
end
