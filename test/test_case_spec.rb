module SES::TestCases
  module TestCase
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
        must_raise(SES::Test::Skip) do
          instance.test_creates_an_example
        end
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
  end
end
