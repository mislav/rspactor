dir = File.dirname(__FILE__)
$:.unshift(dir) unless $:.include?(dir)

require 'rspactor/growl'
require 'spec/runner/formatter/base_formatter'

class RSpecGrowler < Spec::Runner::Formatter::BaseFormatter
  include RSpactor::Growl
  
  def dump_summary(duration, total, failures, pending)
    icon = if failures > 0
      :failed
    elsif pending > 0
      :pending
    else
      :success
    end
    
    message = "#{total} examples, #{failures} failures"
    
    if pending > 0
      message << " (#{pending} pending)"
    end
    
    notify("Test Results", message, icon)
  end
end

