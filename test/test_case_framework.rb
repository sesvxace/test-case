# Comment out this line if you are not running tests externally.
require 'test_case_helper'

module SES::TestCases
  module TestCase
    # Create the generic ExampleTest if it does not yet exist.
    generate_example_case
    
    class FrameworkTest < SES::Test::Spec
      describe 'Test' do SES::Test end
      
      it '.cases returns an array of test cases' do
        subject.cases.must_include ExampleTest
      end
      
      it '.load_cases returns false when tests already loaded' do
        subject.load_cases.must_be_same_as false
      end
      
      it 'defines AssertionError, Skip, and MockError exceptions' do
        subject.constants.select do |constant|
          next unless subject.const_get(constant).respond_to?(:superclass)
          subject.const_get(constant).superclass == StandardError
        end.size.must_be_same_as 3
      end
      
      it 'summarizes run assertions' do
        subject.summarize([true, nil, false, Exception]).must_equal '.SFE'
      end
    end
  end
end
