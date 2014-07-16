module SES::TestCases
  module TestCase
    class CaptureOutputTest < SES::Test::Spec
      describe 'Kernel#capture_output'
    
      it 'captures and returns standard output' do
        capture_output { puts 'Captured.' }.must_equal "Captured.\n"
      end
    end
  end
end
