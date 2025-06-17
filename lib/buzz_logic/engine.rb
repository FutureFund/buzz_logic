require "strscan"

module BuzzLogic
  # The internal engine that parses and evaluates rules.
  # This class is not meant to be used directly. Use BuzzLogic::RulesEngine.evaluate instead.
  class Engine
    # Tokenizer patterns
    TOKEN_PATTERNS = {
      float: /-?\d+\.\d+/,
      integer: /-?\d+/,
      string: /'(?:[^']|\\.)*'|"(?:[^"]|\\.)*"/,
      boolean: /true|false/,
      nil: /nil/,
      identifier: /[a-zA-Z_][a-zA-Z0-9_]*/,
      operator: /==|!=|<=|>=|<|>/,
      logical: /and|or/,
      lparen: /\(/,
      rparen: /\)/,
      dot: /\./,
      space: /\s+/
    }.freeze

    # Operator precedence for the parser
    PRECEDENCE = {
      "or" => 1,
      "and" => 2,
      "==" => 3, "!=" => 3,
      "<" => 4, "<=" => 4, ">" => 4, ">=" => 4
    }.freeze

    def initialize(context)
      @context = context
      @tokens = []
    end

    # Primary method to evaluate a rule string.
    def evaluate(rule_string)
      @tokens = tokenize(rule_string)
      ast = parse
      raise ParsingError, "Invalid or empty rule." if ast.nil?
      eval_ast(ast)
    end

    private

    # Step 1: Tokenization
    def tokenize(rule_string)
      scanner = StringScanner.new(rule_string)
      tokens = []
      until scanner.eos?
        match = nil
        TOKEN_PATTERNS.each do |type, pattern|
          if (match = scanner.scan(pattern))
            tokens << { type: type, value: match } unless type == :space
            break
          end
        end
        raise ParsingError, "Unexpected character at: #{scanner.rest}" unless match || scanner.eos?
      end
      tokens
    end

    # Step 2: Parsing
    def parse(precedence = 0)
      left_node = parse_prefix
      return nil unless left_node

      while !@tokens.empty? && precedence < (PRECEDENCE[@tokens.first[:value]] || 0)
        op_token = @tokens.shift
        right_node = parse(PRECEDENCE[op_token[:value]])
        left_node = { type: :binary_op, op: op_token[:value], left: left_node, right: right_node }
      end

      left_node
    end

    def parse_prefix
      token = @tokens.shift
      case token[:type]
      when :integer, :float, :string, :boolean, :nil
        parse_literal(token)
      when :identifier
        parse_variable(token)
      when :lparen
        parse_grouped_expression
      else
        raise ParsingError, "Unexpected token: #{token[:value]}"
      end
    end

    def parse_literal(token)
      value = token[:value]
      case token[:type]
      when :integer then { type: :literal, value: value.to_i }
      when :float   then { type: :literal, value: value.to_f }
      when :string  then { type: :literal, value: value[1..-2].gsub(/\\./, { "\\'" => "'", '\\"' => '"' }) }
      when :boolean then { type: :literal, value: value == "true" }
      when :nil     then { type: :literal, value: nil }
      end
    end

    def parse_variable(token)
      node = { type: :variable, name: token[:value] }
      while !@tokens.empty? && @tokens.first[:type] == :dot
        @tokens.shift # consume dot
        attr_token = @tokens.shift
        raise ParsingError, "Expected identifier after '.'" unless attr_token && attr_token[:type] == :identifier
        node = { type: :attribute_access, object: node, attribute: attr_token[:value] }
      end
      node
    end

    def parse_grouped_expression
      node = parse(0)
      raise ParsingError, "Expected ')' to close expression" if @tokens.shift&.dig(:type) != :rparen
      node
    end

    # Step 3: AST Evaluation
    def eval_ast(node)
      return node[:value] if node[:type] == :literal

      case node[:type]
      when :variable
        resolve_variable(node[:name])
      when :attribute_access
        object = eval_ast(node[:object])
        resolve_attribute(object, node[:attribute])
      when :binary_op
        left_val = eval_ast(node[:left])
        return true if node[:op] == "or" && left_val
        return false if node[:op] == "and" && !left_val
        right_val = eval_ast(node[:right])
        perform_operation(node[:op], left_val, right_val)
      else
        raise EvaluationError, "Unknown AST node type: #{node[:type]}"
      end
    end

    def resolve_variable(name)
      raise EvaluationError, "Undefined variable: '#{name}'" unless @context.key?(name)
      @context[name]
    end

    def resolve_attribute(object, attribute)
      raise EvaluationError, "Cannot access attribute on nil" if object.nil?

      unless object.respond_to?(:attributes)
        raise EvaluationError, "Object of type #{object.class} does not have an attributes method"
      end

      attrs = object.attributes
      attr_name = attribute.to_s

      if attrs.key?(attr_name)
        attrs[attr_name]
      else
        raise EvaluationError, "Object of type #{object.class} does not have attribute '#{attr_name}'"
      end
    end

    def perform_operation(op, left, right)
      case op
      when "=="  then left == right
      when "!="  then left != right
      when "<"   then left < right
      when "<="  then left <= right
      when ">"   then left > right
      when ">="  then left >= right
      when "and" then !!(left && right)
      when "or"  then !!(left || right)
      else
        raise EvaluationError, "Unknown operator: #{op}"
      end
    rescue ArgumentError => e
      raise EvaluationError, "Type mismatch for operator '#{op}': #{e.message}"
    end
  end
end
