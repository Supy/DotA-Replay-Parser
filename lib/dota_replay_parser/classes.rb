module DotaReplayParser

  DUPLICATE_SKILLING_TIME_LIMIT = 200

  class Entity
	
	  attr_accessor :name, :art, :comment, :cost, :id, :proper_names, :related_to, :type, :extra
	
	  def initialize(entity_name, art, comment, cost, id, proper_names, related_to, type)
				  @name = entity_name
				  @art = art
				  @comment = comment
				  @cost = cost
				  @id = id
				  @proper_names = proper_names
				  @related_to = related_to
				  @type = type
				  @extra
	  end
  end

  class Hero < Entity
	  def get_related_to
		  @related_to.split(",")
	  end
	
  end

  class Item < Entity

  end

  class Skill < Entity
	
  end



  class PlayerStats
	  attr_accessor :kills, :deaths, :assists, :creep_kills, :creep_denies, :neutrals, :end_gold,
		  :inventory, :aa_total, :aa_hits, :ha_total, :ha_hits, :level_cap, :hero, :runes_used
	
	  @level_cap = 1
	
	  def initialize(pid)
		  @pid = pid
		  @inventory = {}
		  @hero = false
		  @delayed_skills = []
		  @runes_used = 0
	  end
	
	

	
	  def is_hero_set?
		  (@hero === false) ? false : true
	  end
	
	  def add_delayed_skill!(skill_data, time, hero_id)
		  @delayed_skills << {:skill_data => skill_data, :time => time, :hero_id => hero_id}
	  end
	
	  def process_delayed_skills!
		  if @delayed_skills.size > 0
			  @delayed_skills.each do |i|
				  @hero.set_skill!(i[:skill_data], i[:time])
			  end
		  end
	  end
	
	
  end

  # Handling activated / used heroes
  class ActivatedHero
	
	  attr_accessor :skills, :id, :name
		
	
	  def initialize(hero_data)
		  @data = hero_data
		  @skills = {}
		  @id = hero_data.id
		  @name = hero_data.name
		  @last_skilled_time = 0 
		  @stats_limit = 0
	  end
	
	  def set_skill!(skill, time)
		  return if (@stats_limit >= 10) and %w(Aamk A0NR).include?(skill.id)
		  return if (time - @last_skilled_time) < DUPLICATE_SKILLING_TIME_LIMIT
		
		  @last_skilled_time = time
		
		  return if @skills.size >= 25
		
		  @skills[time] = skill
		
		  @stats_limit +=1 if %w(Aamk A0NR).include?(skill.id)

	  end
	
	  def level
		  @skills.size
	  end
	
	
  end
end
