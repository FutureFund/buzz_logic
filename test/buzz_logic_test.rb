require "test_helper"

class BuzzLogicTest < Minitest::Test
  UserAddress = Struct.new(:city, :zip) do
    def attributes
      to_h.transform_keys(&:to_s)
    end
  end
  User = Struct.new(:name, :age, :member, :address) do
    def destroy
      raise "This method should not be called in the rules engine"
    end

    def attributes
      to_h.transform_keys(&:to_s)
    end
  end
  Fundraiser = Struct.new(:status, :goal, :team) do
    def attributes
      to_h.transform_keys(&:to_s)
    end
  end

  def setup
    @user = User.new(
      "Alice",
      30,
      true,
      UserAddress.new("New York", "10001")
    )

    @fundraiser = Fundraiser.new("active", 1000.50, nil)

    @context = { "user" => @user, "fundraiser" => @fundraiser }
  end

  # --- Basic Comparisons ---

  def test_evaluates_equality_for_integers
    assert BuzzLogic::RulesEngine.evaluate("user.age == 30", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.age == 29", @context)
  end

  def test_evaluates_equality_for_strings
    assert BuzzLogic::RulesEngine.evaluate("user.name == 'Alice'", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.name == 'Bob'", @context)
  end

  def test_evaluates_inequality
    assert BuzzLogic::RulesEngine.evaluate("user.age != 25", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.age != 30", @context)
  end

  def test_evaluates_greater_than
    assert BuzzLogic::RulesEngine.evaluate("user.age > 20", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.age > 30", @context)
  end

  def test_evaluates_greater_than_or_equal_to
    assert BuzzLogic::RulesEngine.evaluate("user.age >= 30", @context)
    assert BuzzLogic::RulesEngine.evaluate("user.age >= 29", @context)
  end

  def test_evaluates_less_than
    assert BuzzLogic::RulesEngine.evaluate("user.age < 40", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.age < 30", @context)
  end

  def test_evaluates_less_than_or_equal_to
    assert BuzzLogic::RulesEngine.evaluate("user.age <= 30", @context)
    assert BuzzLogic::RulesEngine.evaluate("user.age <= 31", @context)
  end

  def test_handles_float_values
    assert BuzzLogic::RulesEngine.evaluate("fundraiser.goal > 1000.0", @context)
    assert BuzzLogic::RulesEngine.evaluate("fundraiser.goal < 1000.51", @context)
  end

  def test_handles_boolean_values
    assert BuzzLogic::RulesEngine.evaluate("user.member == true", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.member == false", @context)
  end

  def test_handles_nil_values
    assert BuzzLogic::RulesEngine.evaluate("fundraiser.team == nil", @context)
    refute BuzzLogic::RulesEngine.evaluate("user.name == nil", @context)
  end

  # --- Logical Operations ---

  def test_evaluates_and_correctly
    rule = "user.age > 25 and fundraiser.status == 'active'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_short_circuits_and_when_first_operand_is_false
    rule = "user.age < 20 and fundraiser.status == 'active'"
    refute BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_evaluates_or_correctly
    rule = "user.age > 35 or fundraiser.goal > 1000"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_short_circuits_or_when_first_operand_is_true
    rule = "user.age == 30 or fundraiser.goal < 0"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_respects_precedence_and_before_or
    rule = "user.name == 'Bob' and user.age == 20 or fundraiser.status == 'active'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
    rule = "user.member == true or user.age == 20 and fundraiser.status == 'active'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  # --- Grouping and Precedence ---

  def test_overrides_default_precedence_with_parentheses
    rule = "user.name == 'Bob' and (user.age == 20 or fundraiser.status == 'active')"
    refute BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_handles_complex_nested_parentheses
    rule = "((user.age > 20 and user.member == true) or fundraiser.status == 'inactive') and user.address.city == 'New York'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  # --- Nested Attribute Access ---

  def test_accesses_nested_attributes_correctly
    rule = "user.address.city == 'New York'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  def test_handles_multiple_levels_of_nesting
    rule = "user.address.zip != '90210'"
    assert BuzzLogic::RulesEngine.evaluate(rule, @context)
  end

  # --- Error Handling and Security ---

  def test_raises_parsing_error_for_invalid_syntax
    assert_raises(NoMethodError) { BuzzLogic::RulesEngine.evaluate("user.age >=", @context) }
    exception = assert_raises(BuzzLogic::ParsingError) { BuzzLogic::RulesEngine.evaluate("(user.age > 20", @context) }
    assert_equal "Expected ')' to close expression", exception.message
  end

  def test_raises_evaluation_error_for_undefined_variables
    exception = assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate("non_existent.key == 1", @context) }
    assert_equal "Undefined variable: 'non_existent'", exception.message
  end

  def test_raises_evaluation_error_for_undefined_attributes
    assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate("user.non_existent_attribute > 1", @context) }
  end

  def test_raises_evaluation_error_for_attribute_access_on_nil
    rule = "fundraiser.team.name == 'The Bees'"
    exception = assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate(rule, @context) }
    assert_equal "Cannot access attribute on nil", exception.message
  end

  def test_raises_evaluation_error_for_type_mismatches_during_comparison
    rule = "user.age > 'some string'"
    assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate(rule, @context) }
  end

  # --- Security Tests ---
  def test_does_not_evaluate_arbitrary_ruby_code
    malicious_rule = "system('echo pwned')"
    assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate(malicious_rule, @context) }
  end

  def test_does_not_allow_calling_methods_on_objects
    malicious_rule = "user.destroy > 3"
    exception = assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate(malicious_rule, @context) }
    assert_equal "Object of type BuzzLogicTest::User does not have attribute 'destroy'", exception.message
  end

  def test_prevents_calling_methods_with_arguments
    @user.define_singleton_method(:delete_account) { |arg| "deleted with #{arg}" }
    malicious_rule = "user.delete_account('now')"
    assert_raises(BuzzLogic::EvaluationError) { BuzzLogic::RulesEngine.evaluate(malicious_rule, @context) }
  end
end
