module SES::TestCases
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
end
