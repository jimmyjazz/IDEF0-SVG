require_relative 'forward_input_line'
require_relative 'backward_input_line'
require_relative 'forward_guidance_line'
require_relative 'backward_guidance_line'
require_relative 'forward_mechanism_line'
require_relative 'backward_mechanism_line'
require_relative 'external_input_line'
require_relative 'external_output_line'
require_relative 'external_guidance_line'
require_relative 'external_mechanism_line'
require_relative 'unsatisfied_input_line'
require_relative 'unsatisfied_output_line'
require_relative 'unsatisfied_guidance_line'
require_relative 'unsatisfied_mechanism_line'

module IDEF0

  INTERNAL_LINE_TYPES = [
    ForwardInputLine, ForwardGuidanceLine, ForwardMechanismLine,
    BackwardInputLine, BackwardGuidanceLine, BackwardMechanismLine
  ]

  EXTERNAL_LINE_TYPES = [ExternalInputLine, ExternalOutputLine, ExternalGuidanceLine, ExternalMechanismLine]

  UNATTACHED_LINE_TYPES = [UnsatisfiedInputLine, UnsatisfiedOutputLine, UnsatisfiedGuidanceLine, UnsatisfiedMechanismLine]

end
