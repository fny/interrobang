if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'minitest/autorun'
require 'minitest/hell'
require 'minitest/pride'

require File.expand_path('../../lib/interrobang', __FILE__)
