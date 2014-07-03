#--
# Test Case v1.0 by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides a simple unit testing framework for RPG Maker VX Ace
# with very simple expectation-style formatting for test cases. Essentially,
# this script allows you to use test-driven development from within RPG Maker
# VX Ace without depending on an external Ruby installation. This is primarily
# a scripter's tool.
# 
# Usage
# -----------------------------------------------------------------------------
#   There is no succinct way to summarize the usage of this script. However,
# this script is heavily documented with examples if you wish to simply consult
# the supplied documentation. In addition, a usage tutorial is available at
# [SES VXA](http://sesvxace.wordpress.com/2014/04/10/a-case-for-unit-testing/).
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/) for more detailed
# information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below Materials, but above Main and any tests. Place this
# script below the SES Core (v2.0) if you are using it.
# 
#++
module SES
  # ===========================================================================
  # Test
  # ===========================================================================
  # Defines management and running of defined subclasses of SES::Test::Case.
  module Test
    # =========================================================================
    # BEGIN CONFIGURATION
    # =========================================================================
    # Whether or not to automatically run all test cases whenever the game is
    # started in test mode.
    AUTO_RUN = true
    
    # The directory used to store external test files. This path is relative to
    # your game's root directory.
    # NOTE: External test files must have a '.rb' extension to be loaded.
    TEST_DIR = 'System/Tests'
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    # Array of known test cases.
    def self.cases
      @cases ||= []
    end
    
    # Loads external test cases located in the TEST_DIR directory. Returns true
    # if external cases were loaded, false if they already have been.
    def self.load_cases
      return false if @loaded
      Dir.glob(TEST_DIR + '/**/*.rb') { |file| load(file) }
      @loaded = true
    end
    
    # Loads external test cases if they have not yet been loaded, then runs a
    # new instance of every known test case. Provides a Test::Unit-style
    # summary of the run test cases and returns an array of all test results.
    def self.run(options = {})
      load_cases
      start_time = Time.now
      assertions = []
      cases.each { |test_case| assertions.push(*test_case.new.run(options)) }
      puts("Ran #{assertions.size} tests defined in #{cases.size} cases.")
      puts("Test Summary: #{summarize(assertions)}")
      puts("Elapsed Time: %.2f second(s)\n " % (Time.now - start_time))
      assertions
    end
    
    # Provides a Test::Unit-style summary of assertions.
    def self.summarize(assertions)
      assertions.map { |element|
        case element
        when true  then '.'
        when nil   then 'S'
        when false then 'F'
        else            'E'
        end
      }.join
    end
    
    # Definition of standard exceptions for test cases.
    [:AssertionError, :Skip, :MockError].each do |name|
      const_set(name, Class.new(StandardError))
    end
    # =========================================================================
    # Assertable
    # =========================================================================
    # Defines assertions and refutations available to all objects.
    module Assertable
      # =======================================================================
      # Generics
      # =======================================================================
      # Asserts the truth of the passed block. Returns 'true' if the passed
      # block evaluates to 'true', raises an AssertionError otherwise.
      def assert(msg = 'Refuted. No message given.')
        yield.equal?(true) ? true : raise(SES::Test::AssertionError.new(msg))
      end
      
      # Refutes the truth of the passed block. Returns 'true' if the passed
      # block evaluates to 'false', raises an AssertionError otherwise.
      def refute(msg = 'Asserted. No message given.')
        yield.equal?(false) ? true : raise(SES::Test::AssertionError.new(msg))
      end
      # =======================================================================
      # Assertions
      # =======================================================================
      # Positive assertion for testing generic object equality. Example:
      #   'Test'.must_equal('Test') # => true
      def must_equal(obj)
        assert("#{self.inspect} is not equal to #{obj.inspect}.") do
          self == obj
        end
      end
      
      # Positive assertion for testing specific object equality. Example:
      #   1.must_be_same_as(1) # => true
      def must_be_same_as(obj)
        assert("#{self.inspect} is not identical to #{obj.inspect}.") do
          self.equal?(obj)
        end
      end
      
      # Positive assertion for testing comparison operators. Raises an
      # Assertion error if self does not respond to the given operator or if
      # the given operator is not a comparison operator. Example:
      #   1.must_be(:<, 10) # => true
      def must_be(op, obj)
        assert("#{op} is not a comparison operator.") do
          [:==, :!=, :<, :>, :<=, :>=].any? { |o| o == op }
        end
        must_respond_to(op)
        assert("#{self.inspect} is not #{op} #{obj.inspect}.") do
          self.send(op, obj)
        end
      end
      
      # Positive assertion for testing if self responds to the passed method
      # (method name should be given as a symbol). Example:
      #   'Test'.must_respond_to(:size) # => true
      def must_respond_to(sym)
        assert("#{self.inspect} does not respond to ##{sym}.") do
          self.respond_to?(sym)
        end
      end
      
      # Positive assertion for testing if a collection includes an object.
      # Raises an Assertion error if self does not respond to the 'include?'
      # method. Example:
      #   [1, 2, 3].must_include(3) # => true
      def must_include(obj)
        must_respond_to(:include?)
        assert("#{self.inspect} does not include #{obj.inspect}.") do
          self.include?(obj)
        end
      end
      
      # Positive assertion for testing if a collection is empty. Raises an
      # Assertion error if self does not respond to the 'empty?' method.
      # Example:
      #   [].must_be_empty # => true
      def must_be_empty
        must_respond_to(:empty?)
        assert("#{self.inspect} is not empty.") { self.empty? }
      end
      
      # Positive assertion for testing if an object matches the given regular
      # expression. Example:
      #   'Test'.must_match(/\w+/) # => true
      def must_match(regex)
        assert("#{self.inspect} does not match #{regex.inspect}.") do
          self =~ regex ? true : false
        end
      end
      
      # Positive assertion for testing if self is an instance of the passed
      # object. Example:
      #   [].must_be_instance_of(Array) # => true
      def must_be_instance_of(obj)
        assert("#{self.inspect} is not an instance of #{obj.inspect}.") do
          self.instance_of?(obj)
        end
      end
      
      # Positive assertion for testing if self is a kind of the passed object.
      # Example:
      #   42.must_be_kind_of(Numeric) # => true
      def must_be_kind_of(obj)
        assert("#{self.inspect} is not a kind of #{obj.inspect}.") do
          self.kind_of?(obj)
        end
      end
      # =======================================================================
      # Refutations
      # =======================================================================
      # Negative assertion for testing generic object difference. Example:
      #   1.cannot_equal(2) # => true
      def cannot_equal(obj)
        refute("#{self.inspect} is equal to #{obj.inspect}.") { self == obj }
      end
      
      # Negative assertion for testing specific object difference. Example:
      #   'Test'.cannot_be_same_as('Test') # => true
      def cannot_be_same_as(obj)
        refute("#{self.inspect} is identical to #{obj.inspect}.") do
          self.equal?(obj)
        end
      end
      
      # Negative assertion for testing comparison operators. Raises an
      # Assertion error if self does not respond to the given operator or if
      # the given operator is not a comparison operator. Example:
      #   1.cannot_be(:>, 10) # => true
      def cannot_be(op, obj)
        assert("#{op} is not a comparison operator.") do
          [:==, :!=, :<, :>, :<=, :>=].any? { |o| o == op }
        end
        must_respond_to(op)
        refute("#{self.inspect} is #{op} #{obj.inspect}.") do
          self.send(op, obj)
        end
      end
      
      # Negative assertion for testing if self does not respond to the passed
      # method (method name should be given as a symbol). Example:
      #   'Test'.cannot_respond_to(:pop) # => true
      def cannot_respond_to(sym)
        refute("#{self.inspect} responds to ##{sym}.") do
          self.respond_to?(sym)
        end
      end
      
      # Negative assertion for testing if a collection does not include an
      # object. Raises an Assertion error if self does not respond to the
      #'include?' method. Example:
      #   [1, 2, 3].cannot_include(4) # => true
      def cannot_include(obj)
        must_respond_to(:include?)
        refute("#{self.inspect} includes #{obj.inspect}.") do
          self.include?(obj)
        end
      end
      
      # Negative assertion for testing if a collection is not empty. Raises an
      # Assertion error if self does not respond to the 'empty?' method.
      # Example:
      #   [1, 2, 3].cannot_be_empty # => true
      def cannot_be_empty
        must_respond_to(:empty?)
        refute("#{self.inspect} is empty.") { self.empty? }
      end
      
      # Negative assertion for testing if an object does not match the given
      # regular expression. Example:
      #   'Test'.cannot_match(/\d+/) # => true
      def cannot_match(regex)
        refute("#{self.inspect} matches #{regex.inspect}.") do
          self =~ regex ? true : false
        end
      end
      
      # Negative assertion for testing if self is not an instance of the passed
      # object. Example:
      #   42.cannot_be_instance_of(Numeric) # => true
      def cannot_be_instance_of(obj)
        refute("#{self.inspect} is an instance of #{obj.inspect}.") do
          self.instance_of?(obj)
        end
      end
      
      # Negative assertion for testing if self is not a kind of the passed
      # object. Example:
      #   'Test'.cannot_be_kind_of(Class) # => true
      def cannot_be_kind_of(obj)
        refute("#{self.inspect} is a kind of #{obj.inspect}.") do
          self.kind_of?(obj)
        end
      end
      
      # Include the defined assertions and refutations in all objects if the
      # game is being run in test mode.
      Object.send(:include, self) if $TEST
    end
    # =========================================================================
    # DSL
    # =========================================================================
    # A simple DSL for Spec instances.
    module DSL
      # Sets the block to call before each spec is run.
      #   before { subject.push(1, 2, 3) }
      def before(&block)
        define_method(:setup) { instance_eval(&block) }
      end
      alias :before_each :before
      
      # Sets the block to call after each spec is run.
      #   after { subject.clear }
      def after(&block)
        define_method(:teardown) { instance_eval(&block) }
      end
      alias :after_each :after
      
      # Describes a spec for the test case. The passed description is used for
      # display purposes, while the passed block is used as the actual spec to
      # be tested.
      #   it 'should respond to #pop' do
      #     subject.must_respond_to :pop
      #   end
      def it(description = '(undefined)', &block)
        block ||= ->{ skip }
        method_name = ('test_' << description.gsub(/[^\w\?\!]/, '_')).to_sym
        descriptions[method_name] = description
        define_method(method_name, &block)
      end
      alias :specify :it
      
      # Creates a reader method with the passed method_name which returns the
      # value of the passed block (evaluated in the context of the instance).
      #   let :array do Array.new end
      def let(name, &block)
        define_method(name) { eval("@_#{name} ||= instance_eval(&block)") }
      end
      
      # Sets the subject for this test case to the return value of the passed
      # block. This is a convenience method which essentially creates a reader
      # named 'subject' which returns the passed block's return value.
      #   subject { Array.new }
      #   it 'should respond to #pop' do
      #     subject.must_respond_to :pop
      #   end
      def subject(&block)
        let(:subject, &block)
      end
      alias :target :subject
      
      # Sets the displayed name for this test case to the passed name (or the
      # default 'name' of the subject). The block given to this method creates
      # the subject for this test case automatically. The name is set to the
      # name of the subject's class if no name is passed to this method.
      #   describe 'Array' do Array.new end
      #   subject # => []
      def describe(name = nil, &block)
        subject(&block)
        @name = name.nil? ? subject.class.name : name
      end
      
      # Overwrite of 'name' for this instance. Primarily used to format output.
      def name
        defined?(@name) ? @name : super
      end
      alias :to_s :name
    end
    # =========================================================================
    # Reporter
    # =========================================================================
    # Formats test case information and writes information to a given stream.
    class Reporter
      attr_accessor :stream
      
      # Provides output formatting for individual test cases.
      def self.format_case(title, desc, pass, error = nil)
        pass = case pass
        when true  then ' OK '
        when false then 'FAIL'
        when nil   then 'SKIP' end
        pass = 'ERR!' if error
        "  [#{pass}] #{title} #{desc} #{"\n\t -- #{error.message}" if error}"
      end
      
      # Formats the given symbol (by default) into a description string by
      # removing the 'test_' prefix (if it exists) and replacing underscores
      # with spaces. Used by the Case class for writing descriptions for test
      # methods.
      def self.format_desc(symbol)
        symbol.to_s.gsub!(/^test_/, '').gsub!('_', ' ')
      end
      
      # Provides output formatting for the footer of a test case. Essentially
      # writes statistics for the test case.
      def self.format_footer(a)
        n, p, s, f = a.size, a.count(true), a.count(nil), a.count(false)
                 e = a.select { |element| element.kind_of?(Exception) }.size
        "\n  #{n} tests, #{p} passed, #{s} skipped, #{f} failed, #{e} errors\n "
      end
      
      # Provides output formatting for the header of a test case.
      def self.format_header(title)
        "Test Case: #{title}\n"
      end
      
      # Instantiate a new Reporter with the given stream. Streams may be any
      # object which supports the 'puts' method (standard output by default).
      def initialize(stream = $stdout)
        @stream = stream
      end
      
      # Write formatted output to this instance's stream.
      def report(type, *args)
        return nil if !self.class.respond_to?(type = "format_#{type}".to_sym)
        return_value = self.class.send(type, *args)
        @stream.send(:puts, return_value)
        return_value
      end
    end
    # =========================================================================
    # Case
    # =========================================================================
    # Defines a basic test case. All test cases are subclasses of this class.
    class Case
      class << self
        # Class instance variable. Determines whether or not to skip this test
        # suite.
        attr_accessor :skip
      end
      
      # Include the subclass of this class in the Test module's @cases instance
      # variable unless the subclass is already in it (or the subclass is Spec,
      # which is a specialized subclass of Case for specifications).
      def self.inherited(subclass)
        unless Test.cases.include?(subclass) || subclass == SES::Test::Spec
          Test.cases << subclass
        end
        super
      end
      
      # Convenience method for setting the class variable 'skip' to true.
      def self.skip!
        self.skip = true
      end
      
      # An array of runnable test methods used by this instance's 'run' method.
      def runnable_methods
        methods.select { |method| method =~ /^test_/ }
      end
      
      # The reporter instance for this test case.
      def reporter
        @reporter ||= Reporter.new
      end
      
      # Provides specific output directions for each runnable test method. This
      # is defined here to allow redefinition of case output in the Spec class.
      def report_case(string, *values)
        reporter.report(:case, name, Reporter.format_desc(string), *values)
      end
      
      # Convenience method allowing individual test methods to be skipped by
      # calling this method rather than raising a Skip exception manually.
      def skip
        raise(SES::Test::Skip.new)
      end
      
      # Wraps around test methods to ensure they return expected values. This
      # method facilitates the 'setup' and 'teardown' methods and ensures that
      # tests return true, false, nil, or Exception values.
      def wrapper
        begin
          setup if respond_to?(:setup)
          yield ? true : false
        rescue Skip
          nil
        rescue Exception => ex
          ex
        ensure
          teardown if respond_to?(:teardown)
        end
      end
      alias :wrap :wrapper
      
      # Runs all runnable test methods for this test case and returns an array
      # containing each method's return value. Runs are sent to the reporter
      # for formatting and output unless the run is designated as silent.
      def run(options = {})
        return [] if self.class.skip && !options[:force]
        reporter.report(:header, name) unless options[:silent]
        assertions = []
        runnable_methods.each do |runnable|
          val = assertions.push(wrap { method(runnable).call }).last
          unless options[:silent]
            val = val.kind_of?(Exception) ? [false, assertions.last] : [val] 
            report_case(runnable, *val)
          end
        end
        reporter.report(:footer, assertions) unless options[:silent]
        assertions
      end
      
      # The name for this test case. Defaults to the name of this instance's
      # class. Used primarily for output formatting by the reporter.
      def name
        self.class.name
      end
    end
    # =========================================================================
    # Spec
    # =========================================================================
    # Specialized subclass of Case for writing specification-style tests.
    class Spec < Case
      extend DSL
      
      # Hash for containing full descriptions for generated 'test_' methods.
      def self.descriptions
        @descriptions ||= {}
      end
      
      # Reports case information with full descriptions rather than parsed
      # method names (allows for more natural specifications).
      def report_case(method, *values)
        reporter.report(:case, name, self.class.descriptions[method], *values)
      end
    end
    # =========================================================================
    # Mock
    # =========================================================================
    # Provides a basic mock object for use in test cases.
    class Mock
      # Instantiate a new mock object with the passed expectations. Consult the
      # 'expect' method for information on formatting the expectations.
      def initialize(expectations = {})
        @expected = expectations
      end
      
      # Adds a new ghost method to the mock object. The passed 'name' is used
      # as the name of the ghost method, which always returns the passed value.
      # Expected arguments to the ghost method are collected in the 'args'
      # array. Arguments may be given as strict values or as generic classes.
      # If a block is given, it is used to validate the arguments that the
      # ghost method expects. Returns the passed name as a symbol. Examples:
      #   (mock = Mock.new).expect(:specific, true, 'this string')
      #    mock.specific('this string') # => true
      #    mock.specific('any string')  # => MockError
      # 
      #   (mock = Mock.new).expect(:generic, true, String)
      #    mock.generic('any string')   # => true
      # 
      #   (mock = Mock.new).expect(:palindrome?, true, String) do |str|
      #     str.reverse == str
      #   end
      #   mock.palindrome?('evitative') # => true
      #   mock.palindrome?('fails')     # => MockError
      def expect(name, return_value = true, *args, &block)
        @expected[name = name.to_sym] = {
          :returns   => return_value,
          :args      => args,
          :validator => block
        }
        name
      end
      
      # Handles the mock object's ghost methods. Defers to the Class class'
      # implementation of 'method_missing' if the requested method is not an
      # expected method of the mock object.
      def method_missing(name, *args, &block)
        super unless @expected[name]
        exp = @expected[name]
        # Raise a MockError if the ghost method does not receive the mock's
        # expected number of arguments.
        if args.size != exp[:args].size
          msg = "##{name} expected #{exp[:args].size} arguments, "
          raise(MockError.new(msg << "but received #{args.size}."))
        end
        # Raise a MockError if the ghost method receives any arguments of an
        # unexpected type or value.
        unless exp[:args].zip(args).all? { |expected, real| expected === real }
          arg_list = args.map { |e| "#{e.inspect}" }.join(', ')
          msg = "##{name} received unexpected arguments #{arg_list}."
          raise(MockError.new(msg))
        end
        # Raise a MockError if the ghost method's arguments are not validated
        # by the validation block of the expectation.
        if exp[:validator]
          arg_list = args.map { |e| "#{e.inspect}" }.join(', ')
          msg = "##{name} with arguments #{arg_list} failed block validation."
          raise(MockError.new(msg)) unless exp[:validator].call(*args)
        end
        # Everything's in order, so return the ghost method's expected value.
        exp[:returns].respond_to?(:call) ? exp[:returns].call : exp[:returns]
      end
      
      # Redefinition of 'respond_to?' to support the 'method_missing' method's
      # ghosts. Defers to the Class class' implementation of 'respond_to?' if
      # the requested method is not an expected method of the mock object.
      def respond_to?(name, include_private = false)
        @expected[name] ? true : super
      end
    end
    # =========================================================================
    # Stub
    # =========================================================================
    # Provides the 'stub' method for generating stubs of existing methods.
    module Stub
      # Generates a temporary stub of an existing method used during evaluation
      # of the passed block, then returns the method to its original state.
      # This is mostly useful for methods which return varying information --
      # for example, Time.now or Kernel.rand. The method with the passed name
      # is 'stubbed' to return the passed value. Example:
      #   Time.stub(:now, Time.at(0)) do
      #     Time.now # => 1969-12-31 19:00:00 -0500
      #   end
      def stub(name, value, &block)
        begin
          # Generate an alias name.
          aliased_name = "ses_testcase_stubbed_#{name}".to_sym
          # Create the requested stub and alias the original method to the
          # generated alias name.
          singleton_class.send(:alias_method, aliased_name, name)
          singleton_class.send(:define_method, name) do
            value.respond_to?(:call) ? value.call : value
          end
          # Yield the given block so the stub returns the block's value instead
          # of the block object itself.
          yield self if block
        ensure
          # Clean up the stub's generated alias and reset the stubbed method
          # back to its original state.
          singleton_class.send(:undef_method, name)
          singleton_class.send(:alias_method, name, aliased_name)
          singleton_class.send(:undef_method, aliased_name)
        end
      end
      
      # Make all objects capable of generating stubs if the game is being run
      # in test mode.
      Object.send(:include, self) if $TEST
    end
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      Description = Script.new('Test Case', 1.0, :Solistra)
      Register.enter(Description)
    end
  end
end
# =============================================================================
# DataManager
# =============================================================================
module DataManager
  class << self
    alias :ses_testcase_dm_init :init
  end
  
  # Aliased to automatically run test cases if SES::Test::AUTO_RUN is set to a
  # true value. DataManager's default init class method is run first (which
  # allows tests to make use of the standard RGSS3 global variables).
  def self.init(*args, &block)
    ses_testcase_dm_init(*args, &block)
    SES::Test.run if SES::Test::AUTO_RUN && $TEST
  end
end
# =============================================================================
# Kernel
# =============================================================================
module Kernel
  # Captures standard output written to from the passed block and returns the
  # output written as a string.
  def capture_output
    stream = ''
    def stream.write(data)
      self << data
    end
    $stdout = stream
    yield
    $stdout = STDOUT
    stream
  end
  alias :capture :capture_output
end