#--
# SES Test Case Unit Tests
# ==============================================================================
# 
# Summary
# ------------------------------------------------------------------------------
#   This file provides unit tests for the SES Test Case testing framework for
# RPG Maker VX Ace. (Note that some methods in the Test Case framework are not
# possible to test in order to avoid running test suites recursively.)
# 
#++
module SES::TestCases
  # ============================================================================
  # ExampleTest - Sample unit tests. Used by other tests in this suite.
  # ============================================================================
  class ExampleTest < SES::Test::Spec
    describe 'Example'; skip!
    
    it 'always passes' do 1 < 2  end # A passing specification.
    it 'always fails'  do 1 > 2  end # A failing specification.
    it 'always skips'  do skip   end # A skipped specification.
    it 'always errors' do 1.skip end # Specification which produces an error.
    it                               # Empty specification. Should be skipped.
    it 'also always fails' do
      false.must_be_same_as true
      return true
    end # Also a failing specification.
  end
  # ============================================================================
  # FrameworkTest - Unit tests for the SES::Test module.
  # ============================================================================
  class FrameworkTest < SES::Test::Spec
    describe 'Test' do SES::Test end
    
    it '.cases returns an array of test cases' do
      subject.cases.must_include ExampleTest
    end

    it '.load_cases returns false when external tests loaded' do
      subject.load_cases.must_be_same_as false
    end

    it 'defines AssertionError, Skip, and MockError exceptions' do
      subject.constants.select do |constant|
        next unless subject.const_get(constant).respond_to?(:superclass)
        subject.const_get(constant).superclass == StandardError
      end.size.must_be_same_as 3
    end

    it 'summarizes run assertions' do
      exp = '.SFE'
      subject.summarize([true, nil, false, Exception]).must_equal exp
    end
  end
  # ============================================================================
  # CaseTest - Unit tests for the SES::Test::Case class.
  # ============================================================================
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
  # ============================================================================
  # CaseSubclassTest - Unit tests for subclasses of SES::Test::Case.
  # ============================================================================
  class CaseSubclassTest < SES::Test::Spec
    describe 'Case Subclass' do CaseSubclassTest end
    let :instance do subject.new end
    let :results do ExampleTest.new.run(silent: true, force: true) end
    
    it 'is included in SES::Test.cases' do
      SES::Test.cases.must_include subject
    end
    
    it '#run returns an array of expected values' do
      assert 'Contains a value other than true, false, nil, or Exception.' do
        results.any? { |value| ![true, false, nil, Exception].include?(value) }
      end
    end
    
    it 'has defined test methods' do
      instance.runnable_methods.cannot_be_empty
    end

    it '#reporter is an instance of SES::Test::Reporter' do
      instance.reporter.must_be_instance_of SES::Test::Reporter
    end

    it '#skip raises SES::Test::Skip exception' do
      begin
        instance.skip
      rescue SES::Test::Skip; true else false end
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
  # ============================================================================
  # SpecTest - Unit tests for the SES::Test::Spec class.
  # ============================================================================
  class SpecTest < SES::Test::Spec
    describe 'Spec' do SES::Test::Spec end
    let :instance do
      class BlankSpec < subject
        skip!
      end
      BlankSpec.new
    end

    it '#setup is undefined' do
      subject.cannot_respond_to :setup
    end

    it '#teardown is undefined' do
      subject.cannot_respond_to :teardown
    end

    it '.before defines #setup for instance' do
      instance.class.before {}
      instance.must_respond_to :setup
    end

    it '.after defines #teardown for instance' do
      instance.class.after {}
      instance.must_respond_to :teardown
    end

    it '.it defines test methods' do
      instance.class.it('creates an example')
      instance.must_respond_to :test_creates_an_example
    end

    it '.it defines skipped test methods when no block given' do
      begin
        instance.test_creates_an_example
      rescue SES::Test::Skip; true else false end
    end

    it '.it defines test methods with block' do
      instance.class.it('returns 42') { 42 }
      instance.test_returns_42.must_be_same_as 42
    end

    it '.it converts invalid method names to valid method names' do
      instance.class.it('@#testing&^')
      instance.class.descriptions[:test___testing__].must_equal '@#testing&^'
      instance.must_respond_to :test___testing__
    end

    it '.it defines test descriptions in .descriptions' do
      exp = 'creates an example'
      instance.class.descriptions[:test_creates_an_example].must_equal exp
    end

    it '.let creates basic reader methods' do
      instance.class.let(:meaning_of_life) { 42 }
      instance.meaning_of_life.must_equal 42
    end

    it '.let uses instance variables for reader methods' do
      instance.instance_variables.must_include(:@_meaning_of_life)
    end

    it '.subject creates @_subject instance variable and #subject' do
      instance.class.subject { 'This is a test.' }
      instance.must_respond_to :subject
      instance.subject.must_equal 'This is a test.'
    end

    it '.describe defines #name as passed name' do
      instance.send(:remove_instance_variable, :@_subject)
      instance.class.describe('Example') { 'This is an example.' }
      instance.name.must_equal 'Example'
    end

    it '.describe defines subject as passed block' do
      instance.subject.must_equal 'This is an example.'
    end
  end
  # ============================================================================
  # ReporterTest - Unit tests for the SES::Test::Reporter class.
  # ============================================================================
  class ReporterTest < SES::Test::Spec
    describe 'Reporter' do SES::Test::Reporter end
    let :instance do subject.new end
    
    it 'formats header information' do
      subject.format_header('Testing').must_equal "Test Case: Testing\n"
    end
    
    it 'formats case information' do
      exp  = "  [ERR!] Testing description \n\t -- Message"
      args = ['Testing', 'description', true, StandardError.new('Message')]
      subject.format_case(*args).must_equal exp
    end
    
    it 'formats footer information' do
      exp   = "\n  4 tests, 1 passed, 1 skipped, 1 failed, 1 errors\n "
      array = [true, nil, false, StandardError.new]
      subject.format_footer(array).must_equal exp
    end

    it 'formats Case test methods as descriptions' do
      subject.format_desc(:test_is_descriptive).must_equal 'is descriptive'
    end

    it '#report defers to appropriate methods' do
      exp = "Test Case: Testing\n"
      capture_output { instance.report(:header, 'Testing') }.must_equal exp
    end
  end
  # ============================================================================
  # MockTest - Unit tests for the SES::Test::Mock class.
  # ============================================================================
  class MockTest < SES::Test::Spec
    describe 'Mock' do SES::Test::Mock.new end
    after_each      do @_subject = SES::Test::Mock.new end
    
    it 'initializes with given expectations' do
      expectation = { :test => { :returns => 42, :args => [String] } }
      @_subject = SES::Test::Mock.new(expectation)
      subject.instance_eval { @expected }.must_equal expectation
    end
    
    it '#expect returns passed ghost name as Symbol' do
      subject.expect('test').must_be_same_as :test
    end
    
    it 'responds to expected ghosts' do
      subject.expect(:test, true)
      subject.must_respond_to :test
    end
    
    it 'ghosts return expected value' do
      subject.expect(:test, 'value')
      subject.test.must_equal 'value'
    end
    
    it 'ghosts return expected callable value' do
      subject.expect(:test, ->{ 'called value' })
      subject.test.must_equal 'called value'
    end
    
    it 'ghosts (generic) return when given expected types' do
      subject.expect(:test, 42, String)
      subject.test('Meaning of life.').must_be_same_as 42
    end
    
    it 'ghosts (generic) raise MockError given unexpected types' do
      begin
        subject.expect(:test, 42, String)
        subject.test(:meaning)
      rescue SES::Test::MockError; true else false
      end
    end
    
    it 'ghosts (specific) return when given expected values' do
      subject.expect(:test, 42, 'Meaning of life.')
      subject.test('Meaning of life.').must_be_same_as 42
    end
    
    it 'ghosts (specific) raise MockError given unexpected values' do
      begin
        subject.expect(:test, 42, 'Meaning of life.')
        subject.test('Meaning of everything.')
      rescue SES::Test::MockError; true else false
      end
    end
    
    it 'ghosts (validated) return when values pass validation' do
      subject.expect(:test, true, Numeric) { |i| i < 100 }
      subject.test(99).must_be_same_as true
    end
    
    it 'ghosts (validated) raise MockError if values fail validation' do
      begin
        subject.expect(:test, true, Numeric) { |i| i < 100 }
        subject.test(100)
      rescue SES::Test::MockError; true else false
      end
    end
  end
  # ============================================================================
  # StubTest - Unit tests for stub methods.
  # ============================================================================
  class StubTest < SES::Test::Spec
    describe 'Stub' do Object.new end
    
    it 'returns value from block' do
      subject.stub(:object_id, 0) { 1 < 2 }.must_be_same_as true
    end
    
    it 'returns stubbed value when called inside of block' do
      subject.stub(:object_id, 0) { subject.object_id }.must_be_same_as 0
    end
    
    it 'returns original value when called outside of block' do
      subject.stub(:object_id, 0)
      subject.object_id.cannot_be_same_as 0
    end
    
    it 'generates alias of original inside of block' do
      subject.stub(:object_id, 0) do
        subject.ses_testcase_stubbed_object_id
      end.must_be_same_as subject.object_id
    end
    
    it 'removes alias outside of block' do
      subject.stub(:object_id, 0)
      subject.cannot_respond_to :ses_testcase_stubbed_object_id
    end
  end
end
