module SES::TestCases
  module TestCase
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
end
