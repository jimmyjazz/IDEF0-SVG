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
require_relative 'unattached_input_line'
require_relative 'unattached_output_line'
require_relative 'unattached_guidance_line'
require_relative 'unattached_mechanism_line'

module IDEF0

  INTERNAL_LINE_TYPES = [
    ForwardInputLine, ForwardGuidanceLine, ForwardMechanismLine,
    BackwardInputLine, BackwardGuidanceLine, BackwardMechanismLine
  ]

  EXTERNAL_LINE_TYPES = [ExternalInputLine, ExternalOutputLine, ExternalGuidanceLine, ExternalMechanismLine]

  UNATTACHED_LINE_TYPES = [UnattachedInputLine, UnattachedOutputLine, UnattachedGuidanceLine, UnattachedMechanismLine]

end
