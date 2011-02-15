require_relative 'external_input_line'
require_relative 'external_output_line'
require_relative 'external_guidance_line'
require_relative 'external_mechanism_line'
require_relative 'forward_input_line'
require_relative 'backward_input_line'
require_relative 'forward_guidance_line'
require_relative 'backward_guidance_line'
require_relative 'forward_mechanism_line'
require_relative 'backward_mechanism_line'

module IDEF0

  EXTERNAL_LINE_TYPES = [ExternalInputLine, ExternalOutputLine, ExternalGuidanceLine, ExternalMechanismLine]
  INTERNAL_LINE_TYPES = [
    ForwardInputLine, ForwardGuidanceLine, ForwardMechanismLine,
    BackwardInputLine, BackwardGuidanceLine, BackwardMechanismLine
  ]

end
