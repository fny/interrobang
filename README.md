# Interrobang :interrobang:

[![Gem Version](https://badge.fury.io/rb/interrobang.svg)](http://badge.fury.io/rb/interrobang)
[![Build Status](https://travis-ci.org/fny/interrobang.svg?branch=master)](https://travis-ci.org/fny/interrobang)
[![Test Coverage](https://codeclimate.com/github/fny/interrobang/badges/coverage.svg)](https://codeclimate.com/github/fny/interrobang)
[![Code Climate](https://codeclimate.com/github/fny/interrobang/badges/gpa.svg)](https://codeclimate.com/github/fny/interrobang)
[![Inline docs](http://inch-ci.org/github/fny/interrobang.svg?branch=master)](http://inch-ci.org/github/fny/interrobang)

Convert your `predicate_methods?` into `bang_methods!` without abusing `method_missing`.

`Interrobang` currently only works with Ruby versions that support keyword arguments.

## Overview

Say we have the following class:

```ruby
class Answer
  # Say these return a boolean.
  def correct?; end
  def is_correct; end
  def is_factual; end
  def is_right; end
end
```

`Interrobang` automagically adds corresponding bang methods for any predicate methods that end in a `?`. The bang methods explode when the predicate method returns a falsey value and otherwise return true.

```ruby
# Pick your poison...
Interrobang(Answer) # => [:correct!]
Interrobang.bangify(Answer) # => [:correct!]
Interrobang.bangify_class(Answer) # => [:correct!]

answer = Answer.new 
answer.respond_to?(:correct!) # => true (no method missing shenanigans!)
Answer.new.correct! # => Raises Interrobang::FalsePredicate if `#correct?` is false
```

You can add prefixes and suffixes to the generated bang method.

```ruby
Interrobang(Answer, prefix: 'ensure_', suffix: '_or_else')
# => [:ensure_correct_or_else!]
Answer.new.ensure_correct_or_else!
# => Raises Interrobang::FalsePredicate if `#correct?` is false
```

Provide your own blocks to execute on failure. You can optionally access the symbol of the predicate method as an argument.

```ruby
Interrobang(Answer, prefix: 'ensure_') do |predicate_method|
  raise StandardError, predicate_method
end # => [:ensure_correct!]
Answer.new.ensure_correct! # => Raises StandardError if `#correct?` is false
```

Need to convert a single method? No problem.

```ruby
# Pick your poison...
Interrobang(Answer, :correct?) # => :correct!
Interrobang.bangify(Answer, :correct?) # => :correct!
Interrobang.bangify_method(Answer, :correct?) # => :correct!

Interrobang(Answer, :correct?, prefix: 'ensure_', suffix: '_on_saturday') do
  if Time.now.saturday?
    raise WeekendLaziness
  else
    true
  end
end # => :ensure_correct_on_saturday!
```

Beware! `Interrobang` will bangify undefined methods too that classes driven by `method_missing` can be converted too.

```ruby
class NaySayer
  def method_missing(method, *args, &block)
    false
  end
end
Interrobang(NaySayer, :correct?) # => :correct!
```

`Interrobang` returns `nil` instead of converting `bang_methods!` or `assignment_methods`.

### Filters

Perhaps you'd like to convert methods that match a different pattern?

```ruby
Interrobang(Answer, matching: %r{\Ais_.*\z})
# => [:is_correct!, :is_factual!, :is_right!]
```

You can exclude methods that match the pattern with `except`.

```ruby
Interrobang(Answer, matching: %r{\Ais_.*\z}, except: [:is_factual,  :is_right])
# => [:is_correct!]
```

Maybe you'd like to state the methods to convert explicitly? Use `only`. This will override the pattern or any exclusions.

```ruby
Interrobang(Answer, only: :is_correct) # => [:is_correct!]
```

You can opt to include methods from parent classes, but proceed with caution...

```ruby
Interrobang(Answer, include_super: true,  prefix: 'ensure_')
# => [:ensure_correct!, :ensure_nil!, :ensure_eql!, :ensure_tainted!, :ensure_untrusted!, :ensure_frozen!, :ensure_instance_variable_defined!, :ensure_instance_of!, :ensure_kind_of!, :ensure_is_a!, :ensure_respond_to!, :ensure_equal!] 
Answer.new.ensure_nil! # => Raises Interrobang::FalsePredicate
```

Too lazy to type `Interrobang` a few times? Just `extend` it. It's methods are `module_function`s.

```ruby
class Answer
  extend Interrobang
  bangify_method self, :is_correct
  bangify_method self, :is_correct, prefix: 'ensure_'
end
```

### Details

See `lib/interrobang.rb` for complete documentation and the tests for details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interrobang'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install interrobang

## Example Use Case with Rails

`Interrobang` works wonderfully with permission-related objects. Say we have a bangified `Protector` class that defines user permissions in our application:

```ruby
class Protector
  NotSignedIn = Class.new(Exception)
  Unauthorized = Class.new(Exception)

  def initialize(user)
    @user = user
  end

  def signed_in?
    @user.is_a?(User)
  end

  def admin?
    @user && @user.is_admin
  end

  def can_edit_user?(other_user)
    @user && (@user.is_admin || @user.id == other_user.id)
  end

  Interrobang(self, prefix: 'ensure_') do |predicate_method|
    raise Unauthorized, "#{predicate_method} failed"
  end

  Interrobang(self, :signed_in?, prefix: 'ensure_') do |predicate_method|
    raise NotSignedIn, "#{predicate_method} failed"
  end
end
```

In our controller, we can then define rescue handlers for the those exceptions, and add a method to access a `Protector` instance.

```ruby
class ApplicationController < ActionController::Base
  def protector
    @protector ||= Protector.new(current_user)
  end

  rescue_from Protector::NotSignedIn do
    redirect_to sign_in_path, alert: "Please sign in to continue."
  end

  rescue_from Protector::Unauthorized do
    # Handle as you will
  end
end
```

Now we can call `protector.ensure_signed_in!`, `protector.ensure_admin!`, `protector.ensure_can_edit!(other_user)!` from any controller and trigger the errors defined with `Interrobang`.

### Aside: Testing Tricks with Rescue Handlers

For tests, we can stub the rescue handlers with methods that expose the original errors so we can check for them directly.

```ruby
# spec/support/helpers.rb
def raise_handled_rescues(controller = ApplicationController)
  stubbed_handlers = controller.rescue_handlers.map { |rescue_handler|
    name, proc = rescue_handler
    [ name, -> { raise Kernel.const_get(name) } ]
  }
  allow(controller).to receive(:rescue_handlers).and_return(stubbed_handlers)
end
```

This allows us to test that proper errors are being raised independently from testing each error's particular handling.

```ruby
# spec/controllers/users_controller_spec.rb
RSpec.describe UsersController, type: :controller do
  before { raise_handled_rescues }
  after { reset_handled_rescues }
  describe "GET index" do
    context "unauthenticated user" do
      it "raises Protector::NotSignedIn" do
        expect { get :index }.to raise_error(Protector::NotSignedIn)
      end
    end
  end
end

# spec/controllers/application_controller_spec.rb
RSpec.describe ApplicationController, type: :controller do
  describe "Protector::NotSignedIn rescue handler" do
    controller { def index; raise Protector::NotSignedIn; end }
    it "redirects to the sign in page" do
      get :index
      expect(response).to redirect_to sign_in_path
    end
  end
end
```

## What are these predicate methods and bang methods?

**Predicate methods** return a Boolean. By Ruby convention, these methods typically end in a `?`. Other languages like [Scheme][scheme-conventions], [C#][csharp-predicates], [Java][java-predicates], support this interface too.

**Bang methods** are "dangerous" or modify the receiver. By convention, these methods typically end with a `!`. In the case of `Interrobang`, these methods are considered "dangerous" because they may raise an exception.

### Fun Fact

The Ruby conventions for `?` and `!`  are borrowed from [Scheme][scheme-conventions]:

> 1.3.5  Naming conventions
>
>
> By convention, the names of procedures that always return a boolean value usually end in ``?''. Such procedures are called predicates.
>
> By convention, the names of procedures that store values into previously
> allocated locations (see section 3.4) usually end in ``!''. Such procedures
> are called mutation procedures. By convention, the value returned by a 
> mutation procedure is unspecified.

## Development

Be sure to test all the things. Just `rake test`. You can use `bundle console` to play with things in an IRB session.

## Contributing

1. Fork it ( https://github.com/fny/interrobang/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Special Thanks To...

 - [Discourse][discourse] for inspiring me to find a `method_missing`-free alternative to its [EnsureMagic][discourse-ensure]
 - [Michael Josephson][josephson] for [pointing me in the right direction][so-question]
 - To all [contributers][github-contributers]! :beers:

[csharp-predicates]: https://msdn.microsoft.com/en-us/library/bfcke1bz%28v=vs.110%29.aspx "Predicate<T> Delegate"
[java-predicates]: https://docs.oracle.com/javase/8/docs/api/java/util/function/Predicate.html "Interface Predicate<T>"
[scheme-conventions]: http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-4.html#%_sec_1.3.5 "Scheme Naming Conventions"
[discourse]: http://discourse.org "Discourse"
[discourse-ensure]: https://github.com/discourse/discourse/blob/ba0084edee8ace004855b987e1661a7eaff60122/lib/guardian/ensure_magic.rb "module EnsureMagic"
[josephson]: http://www.josephson.org/ "Michael Josephson"
[so-question]: http://stackoverflow.com/questions/28818193/define-method-based-on-existing-method-in-ruby "Define Method Based on Existing Method in Ruby - Stack Overflow"
[github-contributers]: https://github.com/fny/interrobang/graphs/contributors "Predicate Bang Contributers - GitHub"
