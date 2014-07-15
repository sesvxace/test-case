#--
# Test Case: Mocks by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides `Mock` objects which respond to ghost methods for use
# in unit tests. This script is an extension to the core SES Test Case script.
# 
# Requirements
# -----------------------------------------------------------------------------
#   This script does not directly depend upon the core SES Test Case script,
# though its functionality is directly related to it. You may find the core
# Test Case script here:
# 
# * [Test Case]
#   (https://raw.github.com/sesvxace/test-case/master/lib/test-case.rb)
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below the SES Test Case script, but above Main and any
# tests which make use of mock objects.
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
    # MockError
    # =========================================================================
    # Generic exception providing errors as used by {SES::Test::Mock} objects.
    class MockError < StandardError
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
  end
end
