require_relative "buzz_logic/version"
require_relative "buzz_logic/engine"

# Main module for the BuzzLogic Rules Engine from FutureFund.
# The primary entry point is `BuzzLogic::RulesEngine.evaluate`.
module BuzzLogic
  class Error < StandardError; end
  class ParsingError < Error; end
  class EvaluationError < Error; end

  # The main interface for the rules engine.
  module RulesEngine
    # Evaluates a given rule string against a context of objects.
    #
    # @param rule_string [String] The rule to evaluate.
    # @param context [Hash<String, Object>] A hash mapping names to objects.
    # @return [Boolean] The result of the evaluation.
    # @raise [BuzzLogic::ParsingError] if the rule has invalid syntax.
    # @raise [BuzzLogic::EvaluationError] if an error occurs during evaluation.
    def self.evaluate(rule_string, context)
      Engine.new(context).evaluate(rule_string)
    end
  end
end
