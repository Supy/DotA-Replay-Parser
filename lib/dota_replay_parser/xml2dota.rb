##
# DotA Replay Parser
# Authors: Justin Cossutti (justin.cossutti@gmail.com), Tim Sjoberg
# Date: 09/07/11
#
# Based on various works by:
# Seven, Julas, Rush4Hire, esby and Rachmadi
##

require 'nokogiri'

module DotaReplayParser
  class Xml2dota
	
	  attr_accessor :heroes, :skills, :items, :data_map, :skill_to_hero_map
	

	
	  def initialize(filename)
		  f = File.open(filename)
		  doc = Nokogiri::Slop(f).document.html.body
		  f.close
		
	  @heroes = {}
	  @skills = {}
	  @items = {}
	  @data_map = {}
	  @skill_to_hero_map = {}
	
		  doc.itemlist.item.each do |item|
			
			  type = item.itemtype.content.downcase
			
			  case type
				  when "item"
					  temp = Item.new(
						  item.itemname.content, 
						  item.art.content,
						  item.comment.content,
						  item.cost.content,
						  item.itemid.content,
						  item.propernames.content,
						  item.relatedto.content,
						  type
					  )
					  @data_map[temp.id] = temp
					
					
				  when "hero"
					
					  temp = Hero.new(
						  item.itemname.content, 
						  item.art.content,
						  item.comment.content,
						  item.cost.content,
						  item.itemid.content,
						  item.propernames.content,
						  item.relatedto.content,
						  type
					  )
					  @data_map[temp.id] = temp
					
					  skills = temp.get_related_to
					

					  skills.each do |sid|
						  @skill_to_hero_map[sid] = temp.id
					  end
					
				  when "skill", "stat", "ultimate"
					
					  temp = Skill.new(
						  item.itemname.content, 
						  item.art.content,
						  item.comment.content,
						  item.cost.content,
						  item.itemid.content,
						  item.propernames.content,
						  item.relatedto.content,
						  type
					  )
					  @data_map[temp.id] = temp				
					
			  end				
			
		  end	
	

	
	  end
	
  end
end
