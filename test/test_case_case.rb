module SES::TestCases
  # ===========================================================================
  # CaseTest - Unit tests for the SES::Test::Case class.
  # ===========================================================================
  class CaseTest < SES::Test::Spec
    describe 'Case' do SES::Test::Case end
    let :instance   do subject.new end
    
    it 'is not included in SES::Test.cases' do
      SES::Test.cases.cannot_include subject
    end
    
    it '#run returns an Array' do
      instance.run(silent: true).must_be_instance_of Array
    end
    
    it '#run returns an empty Array' do
      instance.run(silent: true).must_be_empty
    end
    
    it 'has no runnable test methods' do
      instance.runnable_methods.must_be_empty
    end

    it 'has access to initialized RGSS3 global variables' do
      $game_switches.cannot_be_same_as nil
    end

    it '.skip! sets the @skip class instance variable to true' do
      instance.class.skip!
      instance.class.skip.must_be_same_as true
    end
  end
end
