# BuzzLogic Rules Engine

Welcome to BuzzLogic, the rules engine that brings the power of dynamic, secure logic to your hive! Built by FutureFund for our online platform for K-12 school groups and PTAs, BuzzLogic makes it easy to evaluate rules without exposing your application to security risks.

It's the bee's knees for handling logic.

## Features

- Dynamic Rules: Define rules as simple strings (e.g., `user.age >= 21 and fundraiser.status == 'active'`).
- Secure by Design: Uses a custom parser and interpreter, avoiding `eval()` and other unsafe methods. Only allows predefined operations, keeping your hive safe.
- Context-Aware: Evaluate rules against a context of one or more objects from your application.
- Rich Operator Support: Includes standard comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`) and logical (`and`, `or`) operators.
- Nested Attribute Access: Safely access nested object attributes (e.g., `user.school.mascot`).
- Extensible: Designed to be easy to extend with custom functions or operators.
- Thoroughly Tested: Comes with a comprehensive Minitest test suite.

## Installation

Add this line to your application's Gemfile:

```
gem "buzz_logic"
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install buzz_logic
```

## Usage

The primary interface for the engine is the BuzzLogic::RulesEngine.evaluate method. It takes two arguments:

- `rule_string` (String): The rule you want to evaluate.
- `context` (Hash): A hash where keys are the names used in the rule (the "buzz words") and values are the corresponding objects.

### Basic Example

```ruby
require "buzz_logic"

# Define some objects to evaluate against
Student = Struct.new(:grade, :has_permission_slip) do
  def attributes
    to_h.map { |k, v| [ k.to_s, v ] }.to_h
  end
end

Fundraiser = Struct.new(:status, :goal_amount) do
  def attributes
    to_h.transform_keys(&:to_s)
  end
end

# The context maps the names used in the rule to the objects
context = {
  "student" => Student.new(grade: 5, has_permission_slip: true),
  "fundraiser" => Fundraiser.new(status: 'active', goal_amount: 500)
}

# Define a rule
rule = "student.grade >= 4 and fundraiser.status == 'active'"

# Evaluate the rule
result = BuzzLogic::RulesEngine.evaluate(rule, context)

puts "Is the student eligible? #{result}" # => true
```

## Supported Syntax

### Operands

- Literals:
  - `String`: e.g., 'active', "Go Bees!"
  - `Integer`: e.g., 5, 1000
  - `Float`: e.g., 99.9
  - `Boolean`: true, false
  - `Nil`: nil
- Variables: Access object attributes using dot notation.
  - `student.grade`
  - `fundraiser.school.principal_name`

### Operators

- Comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Logical: `and`, `or`

Parentheses `()` can be used to group expressions and control precedence.

## Attributes

The object must respond to the `attributes` method and return a hash with string keys (not symbols).

### Security

Security is the queen bee of BuzzLogic's design. Unlike approaches that use eval, BuzzLogic parses the rule into an Abstract Syntax Tree (AST) and then interprets it.

This means:

- **No Arbitrary Code Execution:** A rule like `system('rm -rf /')` will result in a parsing error, not a swarm of problems.
- **No Unsafe Method Calls:** A rule like `student.destroy` is impossible. The interpreter only allows attribute access on the provided context objects, not method calls.

## Development
After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run bundle exec `rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub. Let's build a sweeter future together!

## License

The gem is available as open source under the terms of the MIT License by FutureFund.
