# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dota_replay_parser/version"

Gem::Specification.new do |s|
  s.name        = "dota_replay_parser"
  s.version     = DotaReplayParser::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Justin Cossutti"]
  s.email       = ["justin.cossutti@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Parses Warcraft 3 DotA replays}
  s.description = %q{Pulls various information from the replay files}

  s.rubyforge_project = "dota_replay_parser"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
