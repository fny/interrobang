require File.expand_path('../../test_helper', __FILE__)

SomeError = Class.new(Exception)

describe Interrobang do
  let(:klass) do
    Class.new {
      def true?; true; end
      def veritable?; true; end
      def so_true; true; end
      def so_very_true; true; end
      def false?; false; end
      def so_false; false; end
      def assignment=; end
      def bang!; '!'; end
      def with_argument?(bool); bool; end
    }
  end

  #
  # Bangify Class
  #

  bangify_class_signatures = {
    '#Interrobang' =>
      -> (*args, &block) { Interrobang(*args, &block) },
    '.bangify' =>
      -> (*args, &block) { Interrobang.bangify(*args, &block) },
    '.bangify_class' =>
      -> (*args, &block) { Interrobang.bangify_class(*args, &block) }
  }
  bangify_class_signatures.each do |signature_name, bangify_class|
    describe signature_name do
      it "converts all predicate? methods by default" do
        bangify_class.call klass
        assert klass.new.true!
        assert klass.new.veritable!
      end

      it "returns an array of symbols of the bangified methods" do
        assert_equal bangify_class.call(klass).sort, [:true!, :veritable!, :false!, :with_argument!].sort
      end

      it "converts all methods according to the provided prefix and suffix" do
        bangify_class.call(klass, prefix: 'prefix_', suffix: '_suffix')
        assert klass.new.prefix_true_suffix!
        assert klass.new.prefix_veritable_suffix!
      end

      it "converts all methods that match the provided pattern" do
        bangify_class.call(klass, matching: %r{\Aso_.*\z})
        assert klass.new.so_true!
        assert klass.new.so_very_true!
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "converts all methods that match the provided pattern respected except" do
        bangify_class.call(klass, matching: %r{\Aso_.*\z}, except: [:so_very_true])
        assert klass.new.so_true!
        -> { klass.new.so_very_true! }.must_raise NoMethodError
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "except option accepts a singular symbol" do
        bangify_class.call(klass, matching: %r{\Aso_.*\z}, except: :so_very_true)
        assert klass.new.so_true!
        -> { klass.new.so_very_true! }.must_raise NoMethodError
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "converts only the methods specified in the only option" do
        bangify_class.call(klass, only: [:so_true])
        assert klass.new.so_true!
        -> { klass.new.so_very_true! }.must_raise NoMethodError
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "except option accepts a singular symbol" do
        bangify_class.call(klass, only: :so_true)
        assert klass.new.so_true!
        -> { klass.new.so_very_true! }.must_raise NoMethodError
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "converts only the methods specified in the only option with a block" do
        bangify_class.call(klass, only: [:so_false]) do
          raise SomeError
        end
        -> { klass.new.so_false! }.must_raise SomeError
        -> { klass.new.so_true! }.must_raise NoMethodError
        -> { klass.new.true! }.must_raise NoMethodError
      end

      it "performs the provided block for the bang method" do
        bangify_class.call(klass) do
          raise SomeError
        end
        assert klass.new.true!
        -> { klass.new.false! }.must_raise SomeError
      end

      it "converts super methods when specified" do
        bangify_class.call(klass, include_super: true, prefix: 'ensure_')
        -> { klass.new.ensure_nil! }.must_raise Interrobang::FalsePredicate
      end
    end
  end

  #
  # Bangify Method
  #

  bangify_method_signatures = {
    '#Interrobang' =>
      -> (*args, &block) { Interrobang(*args, &block) },
    '.bangify' =>
      -> (*args, &block) { Interrobang.bangify(*args, &block) },
    '.bangify_method' =>
      -> (*args, &block) { Interrobang.bangify_method(*args, &block) }
  }
  bangify_method_signatures.each do |signature_name, bangify_method|
    describe signature_name do
      describe "with a method that ends in a ?" do
        it "adds a ! method dropping the ?" do
          bangify_method.call(klass, :true?)
          assert klass.new.true!
        end

        it "has no method missing shenanigans" do
          bangify_method.call(klass, :true?)
          assert klass.new.respond_to?(:true!)
        end
      end

      describe "with a method that does not end in a ?" do
        it "adds a ! method" do
          bangify_method.call(klass, :so_true)
        end
      end

      it "returns the symbol of the bangified method" do
        assert_equal bangify_method.call(klass, :true?), :true!
      end

      it "works on methods with arguments" do
        bangify_method.call(klass, :with_argument?)
        assert klass.new.with_argument!(true)
        -> { klass.new.with_argument!(false) }.must_raise Interrobang::FalsePredicate
      end

      it "does not convert assignment methods" do
        assert_equal bangify_method.call(klass, :assignment=), nil
        assert !klass.new.respond_to?(:assignment!)
      end

      it "does not convert bang methods" do
        assert_equal bangify_method.call(klass, :bang!), nil
        assert_equal klass.new.bang!, '!'
      end

      it "converts undefined methods" do
        bangify_method.call(klass, :is_not_defined)
        assert klass.new.respond_to?(:is_not_defined!)
      end

      describe "options" do
        it "adds any provided prefix or suffix to the bang method" do
          bangify_method.call(klass, :true?, prefix: 'prefix_', suffix: '_suffix')
          assert klass.new.prefix_true_suffix!
        end
      end

      describe "falsey predicates" do
        describe "without a custom block" do
          it "raises a FalsePredicate error" do
            bangify_method.call(klass, :false?)
            err = -> { klass.new.false! }.must_raise Interrobang::FalsePredicate
            assert_equal err.message, 'false? is false'
          end
        end

        describe "with a provided block" do
          it "performs the provided block for the bang method" do
            bangify_method.call(klass, :false?) do
              raise SomeError
            end
            -> { klass.new.false! }.must_raise SomeError
          end

          it "allows the provided block to take the predicate method as an argument" do
            bangify_method.call(klass, :false?) do |predicate_method|
              raise SomeError, "#{predicate_method} isn't true"
            end
            err = -> { klass.new.false! }.must_raise SomeError
            assert_equal err.message, "false? isn't true"
          end
        end
      end
    end
  end

  #
  # Everything Else
  #

  it "is extendable" do
    class Answer
      extend Interrobang
      def correct?; end
      bangify(self)
      bangify_class(self)
      bangify_method(self, :correct?)
    end
    -> { Answer.new.correct! }.must_raise(Interrobang::FalsePredicate)
  end

  describe Interrobang::FalsePredicate do
    it "can be rescued without specifying an exception" do
      assert begin raise(Interrobang::FalsePredicate); rescue; true; end
    end
  end
end
