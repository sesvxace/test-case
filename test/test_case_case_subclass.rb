# Comment out this line if you are not running tests externally.
require 'test_case_helper'

module SES::TestCases
  module TestCase
    # Create the generic ExampleTest if it does not yet exist.
    generate_example_case
    
    class CaseSubclassTest < SES::Test::Spec
      describe 'Case Subclass' do CaseSubclassTest end
      let :instance do subject.new end
      let :results do ExampleTest.new.run(silent: true, force: true) end
      
      it 'is included in SES::Test.cases' do
        SES::Test.cases.must_include subject
      end
      
      it '#run returns an array of expected values' do
        assert 'Contains a value other than true, false, nil, or Exception.' do
          results.any? do |value|
            ![true, false, nil, Exception].include?(value)
          end
        end
      end
      
      it 'has defined test methods' do
        instance.runnable_methods.cannot_be_empty
      end
      
      it '#reporter is an instance of SES::Test::Reporter' do
        instance.reporter.must_be_instance_of SES::Test::Reporter
      end
      
      it '#skip raises SES::Test::Skip exception' do
        must_raise(SES::Test::Skip) do
          instance.skip
        end
      end
      
      it 'passes passing tests'  do results[0].must_be_same_as true      end
      it 'flunks failing tests'  do results[1].must_be_same_as false     end
      it 'ignores skipped tests' do results[2].must_be_same_as nil       end
      it 'reports erratic tests' do results[3].must_be_kind_of Exception end
      it 'ignores empty tests'   do results[4].must_be_same_as nil       end
      
      it 'flunks tests with failed assertions' do
        results[5].must_be_same_as false
      end
    end
  end
end
