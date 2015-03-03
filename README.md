# PredicateBang

[![Build Status](https://travis-ci.org/fny/predicate_bang.svg?branch=master)](https://travis-ci.org/fny/predicate_bang)
[![Test Coverage](https://codeclimate.com/github/fny/predicate_bang/badges/coverage.svg)](https://codeclimate.com/github/fny/predicate_bang)
[![Code Climate](https://codeclimate.com/github/fny/predicate_bang/badges/gpa.svg)](https://codeclimate.com/github/fny/predicate_bang)

Convert your `predicate_methods?` into `bangified_predicate_methods!` without
abusing `method_missing`.

Currently only works with Ruby versions that support keywords arguments.

## Overview

```ruby
class Answer
  # Say these return a boolean.
  def correct?; end
  def is_correct; end
  def is_special; end
end

PredicateBang.bangify(Answer)
Answer.new.correct! # => Raises PredicateBang::FalsePredicate if `#correct?` is false

# Add a prefix. You can add suffixes too!
PredicateBang.bangify(Answer, prefix: 'ensure_')
Answer.new.ensure_correct! # => Raises PredicateBang::FalsePredicate if `#correct?` is false

# Provide your own blocks to execute on failure. You can optionally access the
# predicate method as an argument
PredicateBang.bangify(Answer, prefix: 'ensure_') do |predicate_method|
  raise StandardError, predicate_method
end
Answer.new.ensure_correct! # => Raises StandardError if `#correct?` is false

# You can even include parent methods, but proceed with caution:
PredicateBang.bangify(Answer, include_super: true,  prefix: 'ensure_')
Answer.new.ensure_nil! # => Raises PredicateBang::FalsePredicate

# Perhaps you'd like so convert methods that match a different pattern?
PredicateBang.bangify(Answer, matching: %r{\Ais_.*\z}, except: [:is_special])

# Or perhaps you'd like to explicitly state the methods to convert
PredicateBang.bangify(Answer, only: [:is_special])

# You can convert individual methods too:
PredicateBang.bangify_method(Answer, :correct?, prefix: 'ensure_', suffix: '_on_saturday') do
  if Time.now.saturday?
    raise WeekendLaziness
  else
    true
  end
end

# Don't like typing PredicateBang? Just `extend` or `include` it. It's methods are
# module_functions!
```

See `lib/predicate_bang` and the tests for more details.

## What's a predicate method?

A method that returns a Boolean. By Ruby convention, these methods typically end in a `?`. Other languages like [C#](https://msdn.microsoft.com/en-us/library/bfcke1bz%28v=vs.110%29.aspx) and [Java](https://docs.oracle.com/javase/8/docs/api/java/util/function/Predicate.html) support this interface too.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'predicate_bang'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install predicate_bang

## Contributing

1. Fork it ( https://github.com/fny/predicate_bang/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
