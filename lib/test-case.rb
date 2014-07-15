#--
# Test Case v1.2 by Solistra
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

# SES
# =============================================================================
# The top-level namespace for all SES scripts.
module SES
  # Test
  # ===========================================================================
  # Defines management and running of defined subclasses of {SES::Test::Case}.
  module Test
    # =========================================================================
    # BEGIN CONFIGURATION
    # =========================================================================
    
    # Whether or not to automatically run all test cases whenever the game is
    # started in test mode.
    AUTO_RUN = true
    
    # The directory used to store external test files. This path is relative to
    # your game's root directory.
    # 
    # **NOTE:** External test files must have a '.rb' extension to be loaded.
    TEST_DIR = 'System/Tests'
    
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    
    # Returns an array of known test cases.
    # 
    # @return [Array<SES::Test::Case, SES::Test::Spec>] an array of known cases
    def self.cases
      @cases ||= []
    end
    
    # Loads external test cases located in the {SES::Test::TEST_DIR} directory.
    # 
    # @return [Boolean] `true` if test cases were loaded, `false` otherwise
    def self.load_cases
      return false if @loaded
      Dir.glob(TEST_DIR + '/**/*.rb') { |file| load(file) }
      @loaded = true
    end
    
    # Loads external test cases if they have not yet been loaded, then runs a
    # new instance of every known test case. Provides a `Test::Unit`-style
    # summary of the run test cases.
    # 
    # @return [Array] an array of test results
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
    
    # Provides a `Test::Unit`-style summary of assertions.
    # 
    # @param assertions [Array<Boolean, nil, Exception>] the assertions to
    #   summarize
    # @return [String] a summary of assertion results
    def self.summarize(assertions)
      assertions.map { |element|
        case element
        when true  ; '.'
        when nil   ; 'S'
        when false ; 'F'
        else       ; 'E'
        end
      }.join
    end
    # AssertionError
    # =========================================================================
    # Exception raised when assertions are refuted. Causes a failure within the
    # test unit that raises this exception.
    class AssertionError < StandardError
    end
    # Skip
    # =========================================================================
    # Exception raised when a test unit should be skipped.
    class Skip < StandardError
    end
    # MockError
    # =========================================================================
    # Generic exception providing errors as used by {SES::Test::Mock} objects.
    class MockError < StandardError
    end
    # Assertable
    # =========================================================================
    # Defines assertions and refutations available to all objects.
    module Assertable
      # =======================================================================
      # Generics
      # =======================================================================
      
      # Asserts the truth of the passed block.
      # 
      # @raise [SES::Test::AssertionError] if the given block does not evaluate
      #   to a `true` value
      # @return [TrueClass] if the given block evaluates to `true`
      def assert(msg = 'Refuted. No message given.')
        yield.equal?(true) ? true : raise(SES::Test::AssertionError.new(msg))
      end
      
      # Refutes the truth of the passed block.
      # 
      # @raise [SES::Test::AssertionError] if the given block does not evaluate
      #   to a `false` value
      # @return [TrueClass] if the given block evaluates to `false`
      def refute(msg = 'Asserted. No message given.')
        yield.equal?(false) ? true : raise(SES::Test::AssertionError.new(msg))
      end
      
      # =======================================================================
      # Assertions
      # =======================================================================
      
      # Positive assertion for testing generic object equality.
      # 
      # @example
      #   'Test'.must_equal('Test') # => true
      # 
      # @param obj [Object] the object to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_equal
      def must_equal(obj)
        assert("#{self.inspect} is not equal to #{obj.inspect}.") do
          self == obj
        end
      end
      
      # Positive assertion for testing specific object equality.
      # 
      # @example
      #   1.must_be_same_as(1) # => true
      # 
      # @param obj [Object] the object to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_be_same_as
      def must_be_same_as(obj)
        assert("#{self.inspect} is not identical to #{obj.inspect}.") do
          self.equal?(obj)
        end
      end
      
      # Positive assertion for testing comparison operators. Raises an
      # {AssertionError} if self does not respond to the given operator or if
      # the given operator is not a comparison operator.
      # 
      # @example
      #   1.must_be(:<, 10) # => true
      # 
      # @param op [Symbol] the operator to use for testing
      # @param obj [Object] the object to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_be
      def must_be(op, obj)
        assert("#{op} is not a comparison operator.") do
          [:==, :!=, :<, :>, :<=, :>=].any? { |o| o == op }
        end
        must_respond_to(op)
        assert("#{self.inspect} is not #{op} #{obj.inspect}.") do
          self.send(op, obj)
        end
      end
      
      # Positive assertion for testing if `self` responds to the passed method
      # (method name should be given as a symbol).
      # 
      # @example
      #   'Test'.must_respond_to(:size) # => true
      # 
      # @param sym [Symbol] the method name to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_respond_to
      def must_respond_to(sym)
        assert("#{self.inspect} does not respond to ##{sym}.") do
          self.respond_to?(sym)
        end
      end
      
      # Positive assertion for testing if a collection includes an object.
      # Raises an {AssertionError} if `self` does not respond to the
      # `#include?` method.
      # 
      # @example
      #   [1, 2, 3].must_include(3) # => true
      # 
      # @param obj [Object] the object to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_include
      def must_include(obj)
        must_respond_to(:include?)
        assert("#{self.inspect} does not include #{obj.inspect}.") do
          self.include?(obj)
        end
      end
      
      # Positive assertion for testing if a collection is empty. Raises an
      # {AssertionError} if `self` does not respond to the `#empty?` method.
      # 
      # @example
      #   [].must_be_empty # => true
      # 
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_be_empty
      def must_be_empty
        must_respond_to(:empty?)
        assert("#{self.inspect} is not empty.") { self.empty? }
      end
      
      # Positive assertion for testing if an object matches the given regular
      # expression.
      # 
      # @example
      #   'Test'.must_match(/\w+/) # => true
      # 
      # @param regex [RegExp] the regular expression to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_match
      def must_match(regex)
        assert("#{self.inspect} does not match #{regex.inspect}.") do
          self =~ regex ? true : false
        end
      end
      
      # Positive assertion for testing if `self` is an instance of the passed
      # class.
      # 
      # @example
      #   [].must_be_instance_of(Array) # => true
      # 
      # @param obj [Class] the class to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_be_instance_of
      def must_be_instance_of(obj)
        assert("#{self.inspect} is not an instance of #{obj.inspect}.") do
          self.instance_of?(obj)
        end
      end
      
      # Positive assertion for testing if `self` is a kind of the passed class
      # or module.
      # 
      # @example
      #   42.must_be_kind_of(Numeric) # => true
      # 
      # @param obj [Class, Module] the kind of object to test for
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #cannot_be_kind_of
      def must_be_kind_of(obj)
        assert("#{self.inspect} is not a kind of #{obj.inspect}.") do
          self.kind_of?(obj)
        end
      end
      
      # =======================================================================
      # Refutations
      # =======================================================================
      
      # Negative assertion for testing generic object difference.
      # 
      # @example
      #   1.cannot_equal(2) # => true
      # 
      # @param obj [Object] the object to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_equal
      def cannot_equal(obj)
        refute("#{self.inspect} is equal to #{obj.inspect}.") { self == obj }
      end
      
      # Negative assertion for testing specific object difference.
      # 
      # @example
      #   'Test'.cannot_be_same_as('Test') # => true
      # 
      # @param obj [Object] the object to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_be_same_as
      def cannot_be_same_as(obj)
        refute("#{self.inspect} is identical to #{obj.inspect}.") do
          self.equal?(obj)
        end
      end
      
      # Negative assertion for testing comparison operators. Raises an
      # {AssertionError} if `self` does not respond to the given operator or if
      # the given operator is not a comparison operator.
      # 
      # @example
      #   1.cannot_be(:>, 10) # => true
      # 
      # @param op [Symbol] the operator to use for testing
      # @param obj [Object] the object to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_be
      def cannot_be(op, obj)
        assert("#{op} is not a comparison operator.") do
          [:==, :!=, :<, :>, :<=, :>=].any? { |o| o == op }
        end
        must_respond_to(op)
        refute("#{self.inspect} is #{op} #{obj.inspect}.") do
          self.send(op, obj)
        end
      end
      
      # Negative assertion for testing if `self` does not respond to the passed
      # method (method name should be given as a symbol).
      # 
      # @example
      #   'Test'.cannot_respond_to(:pop) # => true
      # 
      # @param sym [Symbol] the method name to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_respond_to
      def cannot_respond_to(sym)
        refute("#{self.inspect} responds to ##{sym}.") do
          self.respond_to?(sym)
        end
      end
      
      # Negative assertion for testing if a collection does not include an
      # object. Raises an {AssertionError} if `self` does not respond to the
      # `#include?` method.
      # 
      # @example
      #   [1, 2, 3].cannot_include(4) # => true
      # 
      # @param obj [Object] the object to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_include
      def cannot_include(obj)
        must_respond_to(:include?)
        refute("#{self.inspect} includes #{obj.inspect}.") do
          self.include?(obj)
        end
      end
      
      # Negative assertion for testing if a collection is not empty. Raises an
      # {AssertionError} if `self` does not respond to the `#empty?` method.
      # 
      # @example
      #   [1, 2, 3].cannot_be_empty # => true
      # 
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_be_empty
      def cannot_be_empty
        must_respond_to(:empty?)
        refute("#{self.inspect} is empty.") { self.empty? }
      end
      
      # Negative assertion for testing if an object does not match the given
      # regular expression.
      # 
      # @example
      #   'Test'.cannot_match(/\d+/) # => true
      # 
      # @param regex [RegExp] the regular expression to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_match
      def cannot_match(regex)
        refute("#{self.inspect} matches #{regex.inspect}.") do
          self =~ regex ? true : false
        end
      end
      
      # Negative assertion for testing if `self` is not an instance of the
      # passed class.
      # 
      # @example
      #   42.cannot_be_instance_of(Numeric) # => true
      # 
      # @param obj [Class] the class to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_be_instance_of
      def cannot_be_instance_of(obj)
        refute("#{self.inspect} is an instance of #{obj.inspect}.") do
          self.instance_of?(obj)
        end
      end
      
      # Negative assertion for testing if `self` is not a kind of the passed
      # class or module.
      # 
      # @example
      #   'Test'.cannot_be_kind_of(Class) # => true
      # 
      # @param obj [Class, Module] the kind of object to test against
      # @raise [SES::Test::AssertionError] if the test fails
      # @return [TrueClass] if the test passes
      # 
      # @see #must_be_kind_of
      def cannot_be_kind_of(obj)
        refute("#{self.inspect} is a kind of #{obj.inspect}.") do
          self.kind_of?(obj)
        end
      end
      
      # Include the defined assertions and refutations in all objects if the
      # game is being run in test mode.
      Object.send(:include, self) if $TEST
    end
    # DSL
    # =========================================================================
    # A simple DSL for {SES::Test::Spec} instances.
    module DSL
      # Sets the block to call before each spec is run.
      # 
      # @example
      #   before { subject.push(1, 2, 3) }
      # 
      # @return [Proc]
      def before(&block)
        define_method(:setup) { instance_eval(&block) }
      end
      alias_method :before_each, :before
      
      # Sets the block to call after each spec is run.
      # 
      # @example
      #   after { subject.clear }
      # 
      # @return [Proc]
      def after(&block)
        define_method(:teardown) { instance_eval(&block) }
      end
      alias_method :after_each, :after
      
      # Describes a spec for the test case. The passed description is used for
      # display purposes, while the passed block is used as the actual spec to
      # be tested.
      # 
      # @example
      #   it 'should respond to #pop' do
      #     subject.must_respond_to :pop
      #   end
      # 
      # @param description [String] the description for this spec
      # @return [Proc]
      def it(description = '(undefined)', &block)
        block ||= ->{ skip }
        method_name = ('test_' << description.gsub(/[^\w\?\!]/, '_')).to_sym
        descriptions[method_name] = description
        define_method(method_name, &block)
      end
      alias_method :specify, :it
      
      # Creates a reader method with the passed name which returns the value of
      # the passed block (evaluated in the context of the instance).
      # 
      # @note This method automatically generates an instance variable with the
      #   name of the reader method prepended with an underscore which contains
      #   the appropriate value.
      # 
      # @example
      #   let :array do Array.new end
      #   it 'demonstrates `#let`' do
      #     array.must_equal []
      #   end
      # 
      # @param name [Symbol] the name of the reader method
      # @return [Proc]
      def let(name, &block)
        define_method(name) { eval("@_#{name} ||= instance_exec(&block)") }
      end
      
      # Sets the subject for this test case to the return value of the passed
      # block. This is a convenience method which essentially creates a reader
      # method named `#subject` which returns the passed block's return value.
      # 
      # @example
      #   subject { Array.new }
      #   it 'should respond to #pop' do
      #     subject.must_respond_to :pop
      #   end
      # 
      # @return [Proc]
      def subject(&block)
        let(:subject, &block)
      end
      alias_method :target, :subject
      
      # Sets the displayed name for this test case to the passed name (or the
      # default `#name` of the subject). The block given to this method creates
      # the subject for this test case automatically. The name is set to the
      # name of the subject's class if no name is passed to this method.
      # 
      # @example
      #   describe 'Array' do Array.new end
      #   subject # => []
      # 
      # @param name [String, nil] the name for this test case; set to `nil` to
      #   use the default name
      # @return [String] the name for this test case
      def describe(name = nil, &block)
        subject(&block)
        @name = name.nil? ? subject.class.name : name
      end
      
      # Overwrite of `#name` for this instance. Primarily used to format
      # output.
      # 
      # @return [String]
      def name
        defined?(@name) ? @name : super
      end
      alias_method :to_s, :name
    end
    # Reporter
    # =========================================================================
    # Formats test case information and writes information to a given stream.
    class Reporter
      # The output stream this {Reporter} should write to.
      # @return [Object]
      attr_accessor :stream
      
      # Provides output formatting for individual test units.
      # 
      # @param title [#to_s] the name of the test case
      # @param desc [#to_s] the description of this test unit
      # @param pass [Boolean, nil] `true` if the unit passed, `false` if it
      #   failed for any reason, `nil` if it was skipped
      # @param error [Exception] the error encountered if the test failed due
      #   to a raised exception
      # @return [String] the formatted test unit information
      def self.format_case(title, desc, pass, error = nil)
        pass = case pass
        when true  then ' OK '
        when false then 'FAIL'
        when nil   then 'SKIP' end
        pass = 'ERR!' if error
        "  [#{pass}] #{title} #{desc} #{"\n\t -- #{error.message}" if error}"
      end
      
      # Formats the given symbol (by default) into a descriptive string by
      # removing the 'test_' prefix (if it exists) and replacing underscores
      # with spaces.
      # 
      # @note This method is used by the {Case} class for writing descriptions
      #   for test methods.
      # 
      # @param symbol [#to_s] the descriptive symbol to format
      # @return [String] the formatted description
      def self.format_desc(symbol)
        symbol.to_s.gsub!(/^test_/, '').gsub!('_', ' ')
      end
      
      # Provides output formatting for the footer of a test case. Essentially
      # writes statistics for the test case.
      # 
      # @param a [Array<Boolean, nil, Exception>] an array of assertions to
      #   format; see {Case#wrapper} for more information about how assertions
      #   are coerced into values
      # @return [String] the formatted footer
      # 
      # @see Case#wrapper
      def self.format_footer(a)
        n, p, s, f = a.size, a.count(true), a.count(nil), a.count(false)
                 e = a.select { |element| element.kind_of?(Exception) }.size
        "\n  #{n} tests, #{p} passed, #{s} skipped, #{f} failed, " << \
          "#{e} errors\n "
      end
      
      # Provides output formatting for the header of a test case.
      # 
      # @param title [#to_s] the title for the header
      # @return [String] the formatted header
      def self.format_header(title)
        "Test Case: #{title}\n"
      end
      
      # Instantiate a new {Reporter} with the given stream. Streams may be any
      # object which responds to the `#puts` method (standard output by
      # default).
      # 
      # @param stream [#puts] the stream to write reports to
      # @return [self]
      def initialize(stream = $stdout)
        @stream = stream
      end
      
      # Writes formatted output to this instance's `@stream`.
      # 
      # @note The given `type` is used to call an appropriate `.format_` method
      #   which takes the given `args` and performs output formatting. Consult
      #   the appropriate formatting methods for more information.
      # 
      # @param type [#to_s] the type of report to create; by default, may be
      #   one of `:case`, `:desc`, `:footer`, or `:header`
      # @param args [Array] the arguments to pass to the requested formatter
      # @return [String] the formatted report
      # 
      # @see .format_case
      # @see .format_desc
      # @see .format_footer
      # @see .format_header
      def report(type, *args)
        return nil if !self.class.respond_to?(type = "format_#{type}".to_sym)
        return_value = self.class.send(type, *args)
        @stream.send(:puts, return_value)
        return_value
      end
    end
    # Case
    # =========================================================================
    # Defines a basic test case. All test cases are subclasses of this class.
    class Case
      class << self
        # Whether or not to skip this test suite.
        # @return [Boolean]
        attr_accessor :skip
      end
      
      # Include the subclass of this class in the Test module's `@cases`
      # instance variable unless the subclass is already in it (or the subclass
      # is {Spec}, a specialized subclass of {Case} for specifications).
      # 
      # @param subclass [Class] the class which inherited this class
      # @return [nil]
      def self.inherited(subclass)
        unless Test.cases.include?(subclass) || subclass == SES::Test::Spec
          Test.cases << subclass
        end
        super
      end
      
      # Convenience method for setting the class instance variable `@skip` to a
      # `true` value.
      # 
      # @return [TrueClass]
      def self.skip!
        self.skip = true
      end
      
      # An array of runnable test methods used by this instance's {#run}
      # method.
      # 
      # @return [Array<Symbol>]
      def runnable_methods
        methods.select { |method| method =~ /^test_/ }
      end
      
      # The {SES::Test::Reporter} instance for this test case.
      # 
      # @return [SES::Test::Reporter]
      def reporter
        @reporter ||= Reporter.new
      end
      
      # Provides specific output directions for each runnable test method. This
      # is defined here to allow redefinition of case output in the {Spec}
      # class.
      # 
      # @param string [String] the string to format for output by a {Reporter}
      # @return [String] the formatted report
      def report_case(string, *values)
        reporter.report(:case, name, Reporter.format_desc(string), *values)
      end
      
      # Convenience method allowing individual test methods to be skipped by
      # calling this method rather than raising a {Skip} exception manually.
      # 
      # @raise [SES::Test::Skip]
      def skip
        raise(SES::Test::Skip.new)
      end
      
      # Wraps around test methods to ensure they return expected values. This
      # method facilitates the `#setup` and `#teardown` methods and ensures
      # that tests return `true`, `false`, `nil`, or `Exception` values.
      # 
      # @return [Boolean, nil, Exception] the return value of the test method
      #   coerced into a `true`, `false`, `nil`, or `Exception` value
      def wrapper
        setup if respond_to?(:setup)
        yield ? true : false
      rescue Skip
        nil
      rescue Exception => ex
        ex.class == AssertionError ? false : ex
      ensure
        teardown if respond_to?(:teardown)
      end
      alias_method :wrap, :wrapper
      
      # Runs all runnable test methods for this test case and returns an array
      # containing each method's return value. Runs are sent to the reporter
      # for formatting and output unless the run is designated as silent.
      # 
      # @param options [Hash{Symbol => Boolean}] hash of options; suitable keys
      #   are `:force` and `:silent` with appropriate boolean values
      # @return [Array<Object>] an array of return values from each runnable
      #   test method
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
      # 
      # @return [String] the name for this test case
      def name
        self.class.name
      end
    end
    # Spec
    # =========================================================================
    # Specialized subclass of {SES::Test::Case} for writing specification-style
    # tests.
    class Spec < Case
      extend DSL
      
      # Hash for containing full descriptions for generated `#test_` methods.
      # 
      # @return [Hash{Symbol => String}]
      def self.descriptions
        @descriptions ||= {}
      end
      
      # Reports case information with full descriptions rather than parsed
      # method names (allows for more natural specifications).
      # 
      # @param method [Symbol] the method to obtain a description for
      # @param values [Array] an array of values to pass to {Reporter#report}
      # @return [String] the formatted report
      def report_case(method, *values)
        reporter.report(:case, name, self.class.descriptions[method], *values)
      end
    end
    # Mock
    # =========================================================================
    # Provides a basic mock object for use in test cases.
    class Mock
      # Instantiate a new mock object with the passed expectations. Consult the
      # {#expect} method for information on formatting the expectations.
      # 
      # @param expectations [Hash{Symbol => Object}] the expectations to add to
      #   this {Mock} instance
      # @return [self] the new {Mock} instance
      # 
      # @see #expect
      def initialize(expectations = {})
        @expected = expectations
      end
      
      # Adds a new ghost method to the mock object. The passed `name` is used
      # as the name of the ghost method, which always returns the passed value.
      # Expected arguments to the ghost method are collected in the `args`
      # array. Arguments may be given as strict values or as generic classes.
      # If a block is given, it is used to validate the arguments that the
      # ghost method expects. Returns the passed name as a symbol.
      # 
      # @example Specific Ghost Methods
      #   mock = Mock.new
      #   mock.expect(:specific, true, 'this string')
      #   mock.specific('this string') # => true
      #   mock.specific('any string')  # => MockError
      # 
      # @example Generic Ghost Methods
      #   mock = Mock.new
      #   mock.expect(:generic, true, String)
      #   mock.generic('any string') # => true
      # 
      # @example Callable Ghost Methods
      #   mock = Mock.new
      #   mock.expect(:palindrome?, true, String) do |str|
      #     str.reverse == str
      #   end
      #   mock.palindrome?('evitative') # => true
      #   mock.palindrome?('fails')     # => MockError
      # 
      # @param name [#to_sym] the name of the ghost method
      # @param return_value [Object] the value for the ghost method to return
      # @param args [Array] the arguments for the ghost method to expect
      # @return [Symbol] the name of the ghost method
      def expect(name, return_value = true, *args, &block)
        @expected[name = name.to_sym] = {
          :returns   => return_value,
          :args      => args,
          :validator => block
        }
        name
      end
      
      # Handles the mock object's ghost methods. Defers to the `Class` class'
      # implementation of `#method_missing` if the requested method is not an
      # expected method of the mock object.
      # 
      # @param name [Symbol] the name of the missing method
      # @param args [Array] an array of arguments to pass to the method
      # @raise [NoMethodError] if there is no ghost method with the given
      #   method name
      # @return [Object] the return value of the ghost method
      # 
      # @see #expect
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
      
      # Redefinition of `respond_to?` to support the {#method_missing} method's
      # ghosts. Defers to the `Class` class' implementation of `respond_to?` if
      # the requested method is not an expected method of the mock object.
      # 
      # @param name [Symbol] the method name to test for responsiveness
      # @param include_private [Boolean] whether or not to include private
      #   methods when testing responsiveness
      # @return [Boolean] `true` if the instance responds to the given method
      #   name, `false` otherwise
      def respond_to?(name, include_private = false)
        @expected[name] ? true : super
      end
    end
    # Stub
    # =========================================================================
    # Provides the {#stub} method for generating stubs of existing methods.
    module Stub
      # Generates a temporary stub of an existing method used during evaluation
      # of the passed block, then returns the method to its original state.
      # This is mostly useful for methods which return varying information --
      # for example, `Time.now` or `Kernel.rand`. The method with the passed
      # name is 'stubbed' to return the passed value.
      # 
      # @example
      #   Time.stub(:now, Time.at(0)) do
      #     Time.now # => 1969-12-31 19:00:00 -0500
      #   end
      # 
      # @param name [Symbol] the method name to stub
      # @param value [Object, #call] the value for the stub to return; `#call`
      #   is called upon the value if it responds to this method
      # @return [Object] the return value of the given block
      def stub(name, value, &block)
        # Generate an alias name.
        aliased_name = "ses_testcase_stubbed_#{name}".to_sym
        # Create the requested stub and alias the original method to the
        # generated alias name.
        singleton_class.send(:alias_method, aliased_name, name)
        singleton_class.send(:define_method, name) do
          value.respond_to?(:call) ? value.call : value
        end
        # Yield the given block so the stub returns the block's value.
        yield self if block_given?
      ensure
        # Clean up the stub's generated alias and reset the stubbed method
        # back to its original state.
        singleton_class.send(:undef_method, name)
        singleton_class.send(:alias_method, name, aliased_name)
        singleton_class.send(:undef_method, aliased_name)
      end
      
      # Make all objects capable of generating stubs if the game is being run
      # in test mode.
      Object.send(:include, self) if $TEST
    end
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      # Script metadata.
      Description = Script.new('Test Case', 1.2, :Solistra)
      Register.enter(Description)
    end
  end
end
# DataManager
# =============================================================================
# Manages the database and game objects.
module DataManager
  class << self
    # Aliased to automatically run test cases if {SES::Test::AUTO_RUN} is set
    # to a `true` value. {DataManager}'s default {DataManager.init .init} class
    # method is run first (which allows tests to make use of the standard RGSS3
    # global variables).
    # 
    # @see .init
    alias_method :ses_testcase_dm_init, :init
  end
  
  # Initializes the standard global variables used by RGSS3.
  # 
  # @return [void]
  def self.init(*args, &block)
    ses_testcase_dm_init(*args, &block)
    SES::Test.run if SES::Test::AUTO_RUN && $TEST
  end
end
# Kernel
# =============================================================================
# Methods defined here are automatically available to all Ruby objects.
module Kernel
  # Captures standard output written to from the passed block and returns the
  # output written as a string.
  # 
  # @return [String] the captured output
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
  alias_method :capture, :capture_output
end
