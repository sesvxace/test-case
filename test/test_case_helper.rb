module SES::TestCases
  module TestCase
    def self.generate_example_case
      return nil if const_defined?(SES::TestCases::ExampleTest)
      eval %Q{
      class ExampleTest < SES::Test::Spec
        describe 'Example'; skip!
        
        it 'always passes' do 1 < 2  end # A passing specification.
        it 'always fails'  do 1 > 2  end # A failing specification.
        it 'always skips'  do skip   end # A skipped specification.
        it 'always errors' do 1.skip end # Produces an error.
        it                               # Empty specification. To be skipped.
        
        it 'also always fails' do
          false.must_be_same_as true
          return true
        end # Also a failing specification.
      end
      }
    end
  end
end
