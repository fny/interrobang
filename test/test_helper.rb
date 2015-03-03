require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'minitest/autorun'
require 'minitest/pride'

require File.expand_path('../../lib/predicate_bang', __FILE__)
