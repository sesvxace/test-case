module SES::TestCases
  module TestCase
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
        must_raise(SES::Test::MockError) do
          subject.expect(:test, 42, String)
          subject.test(:meaning)
        end
      end
      
      it 'ghosts (specific) return when given expected values' do
        subject.expect(:test, 42, 'Meaning of life.')
        subject.test('Meaning of life.').must_be_same_as 42
      end
      
      it 'ghosts (specific) raise MockError given unexpected values' do
        must_raise(SES::Test::MockError) do
          subject.expect(:test, 42, 'Meaning of life.')
          subject.test('Meaning of everything.')
        end
      end
      
      it 'ghosts (validated) return when values pass validation' do
        subject.expect(:test, true, Numeric) { |i| i < 100 }
        subject.test(99).must_be_same_as true
      end
      
      it 'ghosts (validated) raise MockError if values fail validation' do
        must_raise(SES::Test::MockError) do
          subject.expect(:test, true, Numeric) { |i| i < 100 }
          subject.test(100)
        end
      end
    end
  end
end
