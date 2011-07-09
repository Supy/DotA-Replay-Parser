##
# DotA Replay Parser
# Authors: Justin Cossutti (justin.cossutti@gmail.com), Tim Sjoeberg
# Date: 09/07/11
#
# Based on various works by:
# Seven, Julas, Rush4Hire, esby and Rachmadi
##

module DotaReplayParser
  class GenericMode
	  attr_accessor :short_name, :full_name
		
  end

  class CDMode < GenericMode
	
	  attr_accessor :hero_pool, :hero_bans, :hero_picks, :bans_per_team
	
	  def initialize
		
		  @bans_per_team = 2
		  @hero_pool = []
		  @hero_bans = []
		  @hero_picks = []
		  @short_name = "cd"
		  @full_name = "Captain's Draft"
		
	  end
	
	  def ban_hero!(hero)
		  @hero_bans << hero
	  end
	
	  def pick_hero!(hero)
		  @hero_picks << hero
	  end
	
	  def add_to_hero_pool(hero)
		  @hero_pool << hero
	  end
	
	  def num_picks
		  @hero_picks.size
	  end
		
	
  end

  class CMMode < GenericMode
	
	  attr_accessor :hero_bans, :hero_picks, :bans_per_team
	
	  def initialize		
		  @bans_per_team = 3
		  @hero_bans = []
		  @hero_picks = []
		  @short_name = "cm"
		  @full_name = "Captain's Mode"		
	  end
	
	  def ban_hero!(hero)
		  @hero_bans << hero
	  end
	
	  def pick_hero!(hero)
		  @hero_picks << hero
	  end
	
	  def num_picks
		  @hero_picks.size
	  end
	
	  def num_bans
		  @hero_bans.size
	  end
	
	  def ban_phase_complete?		
		  (@hero_bans.size >= (@bans_per_team*2)) ? true : false		
	  end
		
	
  end
end
