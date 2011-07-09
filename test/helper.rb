gem 'minitest'
require 'minitest/autorun'
require 'purdytest'

$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'dota_replay_parser'
require 'test/unit'
