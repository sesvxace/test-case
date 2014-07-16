#--
# Test Case: Assertions by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides useful assertion and refutation methods available to
# all objects when the game is run in test mode. This script is an extension to
# the core SES Test Case script.
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
# tests which make use of assertions or refutations.
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
    # AssertionError
    # =========================================================================
    # Exception raised when assertions are refuted. Causes a failure within the
    # test unit that raises this exception.
    class AssertionError < StandardError
    end
    # Assertable
    # =========================================================================
    # Defines assertions and refutations available to all objects.
    module Assertable
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
  end
end
# Kernel
# =============================================================================
# Methods defined here are automatically available to all Ruby objects.
module Kernel
  # Positive assertion for testing if the given block raises the given
  # exception class.
  # 
  # @param exception [Exception] the exception class to test for
  # @raise [Exception] if an exception other than the one tested for is raised
  # @return [Boolean] `true` if the test passes, `false` otherwise
  def must_raise(exception = StandardError)
    yield
  rescue exception
    true
  rescue Exception => ex
    raise ex
  else
    false
  end
  
  # Negative assertion for testing that the given block does not raise the
  # given exception class.
  # 
  # @param exception [Exception] the exception class to test against
  # @raise [Exception] if an exception other than the one tested against is
  #   raised
  # @return [Boolean] `true` if the test passes, `false` otherwise
  def cannot_raise(exception = StandardError)
    yield
  rescue exception
    false
  rescue Exception => ex
    raise ex
  else
    true
  end
end
