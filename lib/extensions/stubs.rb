#--
# Test Case: Stubs by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides the ability to generate method stubs which will return
# the passed value you give to them for unit testing purposes. This script is
# an extension to the core SES Test Case script.
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
# tests which make use of method stubs.
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
  end
end
