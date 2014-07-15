#--
# Test Case: Capture Output by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides a method for capturing output written to standard
# output and returning the captured data designed for use in unit testing. This
# script is designed as an extension to the core SES Test Case script.
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
# tests which make use of standard output capturing.
# 
#++

# Kernel
# =============================================================================
# Methods defined here are automatically available to all Ruby objects.
module Kernel
  # Captures standard output written to from the passed block and returns the
  # output written as a string.
  # 
  # @example
  #   capture_output do
  #     # This will not be written to `STDOUT`.
  #     puts 'Captured.'
  #   end # => "Captured.\n"
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
