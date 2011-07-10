##
# DotA Replay Parser
# Authors: Justin Cossutti (justin.cossutti@gmail.com), Tim Sjoberg
# Date: 09/07/11
#
# Based on various works by:
# Seven, Julas, Rush4Hire, esby and Rachmadi
##

require 'zlib'
require 'dota_replay_parser/convert.rb'
require 'dota_replay_parser/xml2dota.rb'
require 'dota_replay_parser/modes.rb'
require 'dota_replay_parser/classes.rb'

module DotaReplayParser
  class Replay 
	
	  DEFAULT_XML_MAP = "dota.allstars.v6.70.xml"
	  XML_MAP_BASE_NAME = "dota.allstars.v"		
	  MAPS_FOLDER = "maps"
	
	  NUM_OF_PICKS = 10
	  NUM_OF_BANS = 4
	  ACTION_DELAY = 650
	
	  attr_accessor :game, :players, :observers, :chat, :bans, :stats, :extra

	
	  def initialize(filename)
		
		  @max_datablock = 1500
		  @retraining_time = 15000

		  @time = 0
		  @paused = false

		  @game = {}
		  @header = {}
		  @players = {}
		  @observers = {}
		  @chat = []

		  #CM Mode
		  @in_pick_mode = false
		  @bans = @picks = []
		  @num_picks = 0
		  @num_bans = 0

		  @swap_heroes = []
		  @slot_to_player_map = {}
		  @stats = {}
		  @extra = {}

		  @previous_pick

		  @activated_heroes = {}

		  @preannounce_pick = @preannounce_skill = {}	
		  @dota_mode

		  @w3id2names = @dotaid2w3id= @translated_dotaid = {}

		  @leaves = 0	
	
		  @filename = filename
		  @game[:player_count] = 0

		  begin
			  @file = File.new(@filename, "rb")
		  rescue
			  raise "Error opening file #{@filename}"
		  end

		  @file.flock(File::LOCK_EX)

		  self.parse_header!
		  self.parse_data!
		  self.cleanup!
		
		  @file.flock(File::LOCK_UN)
		  @file.close
			
		
	  end

	  def parse_header!

		  @data = @file.read(48)
		  @header[:intro], @header[:header_size], @header[:c_size], @header[:header_v], @header[:u_size], @header[:blocks] = @data.unpack("A28LLLLL")
		
		  if @header[:intro] != "Warcraft III recorded game\x1A"
			  raise "Not a replay file!"
			  exit
		  end

		  @data = @file.read(20)
		  @header[:ident], @header[:major_v], @header[:build_v], @header[:flags], @header[:length], @header[:checksum] = @data.unpack("a4LSSLL")

		  @header[:minor_v] = 0
		  @header[:ident].reverse!


		  if @header[:major_v] < 7
			  raise "Replay version not supported."
			  exit
		  end		

	  end

	  def parse_data!

		  @file.seek(@header[:header_size])

		  blocks = @header[:blocks].to_i
		
		  blocks.times do |i|

			  block_h = {}		
			  block_h[:c_size], block_h[:u_size], block_h[:checksum] = @file.read(8).unpack("SSL")


			  temp = @file.read(block_h[:c_size])


			  temp = temp[2..-5]

			  temp[0] = (temp[0].ord + 1).chr
			
			  temp = self.inflate(temp)
			  @data << temp


			  if i == 0

				  @data = @data[24..-1]
				  self.load_player!
				  self.load_game!
				
				  @extra[:parsed] = true
			  elsif (blocks - i) < 2
				  @max_datablock = 0
			  end

			
			  self.parse_blocks!		
				
		  end
		

			
	  end

	  def load_player!


		  temp = {}
		  temp[:record_id], temp[:player_id], temp[:name] = @data.unpack("CC")
		

		  @data = @data[2..-1]

		  pid = temp[:player_id]

		  @players[pid] = {:pid => pid, :name => "", :actions => [], :actions_details => {}, :items => {}, :last_time => 0}

		  @players[pid][:initiator] = self.true?(!temp[:record_id])



		  i = 0
		  while(@data[i] != 0.chr) do		
			  @players[pid][:name] << @data[i]
			  i=i+1
		  end

		  # Save for handling SP
		  @w3id2names[pid] = @players[pid][:name]

		  # If FFA, we give them some names
		  if @players[pid][:name].empty?
			  @players[pid][:name] = "Player #{pid}"
		  end
		
		  @data = @data[(i+1)..-1]

		  # Custom game
		  if @data[0].ord == 1 
			  @data = @data[2..-1]
			
		  # Ladder game (irrelevant to dota)
		  elsif @data[0].ord == 8
			  @data = @data[9..-1]
		  end
		

		  if !@header[:build_v]
			  @players[pid][:team] = (pid-1)%2
		  end

		  @players[pid][:actions] << 0
		  @game[:player_count] = @game[:player_count]+1;
			
			
		

	  end

	  def load_game!

		  @game[:name] = ""
		  i = 0
		  while(@data[i] != "\x00") do
			  @game[:name] << @data[i]
			  i=i+1
		  end

		  @data = @data[(i+2)..-1]


		  # 4.3 [Encoded String]

		  temp = ""
		  i = 0
	
		  while (@data[i] != 0.chr) do
			  if i%8 == 0
				  mask = @data[i].ord
			  else
				  # Ruby considers 0 as true. If result = 0 (which is false in other languages), flip it to true and vice versa.
				  # i.e. cannot say !0 = true in Ruby, as !(true) = false
				  result = ((mask & (1 << (i%8))) > 0) ? 0 : 1
				  temp << (@data[i].ord - result).chr
			  end
			  i = i+1
		  end

		  @data = @data[i+1..-1]



		  @game[:speed] = Convert.speed(temp[0].ord)

		  if (temp[1].ord & 1)
			  @game[:visibility] = Convert.visibility(0)
		  elsif (temp[1].ord & 2)
			  @game[:visibility] = Convert.visibility(1)
		  elsif (temp[1].ord & 4)
			  @game[:visibility] = Convert.visibility(2)
		  elsif (temp[1].ord & 8)
			  @game[:visibility] = Convert.visibility(3)
		  end

		  @game[:observers] = Convert.observers(Convert.bool2num((temp[1].ord & 16)) + 2*Convert.bool2num((temp[1].ord & 32)))
		  @game[:teams_together] = Convert.num2bool(temp[1].ord & 64)

		  @game[:lock_teams] = Convert.num2bool(temp[2].ord)
		  @game[:full_shared_unit_control] = Convert.num2bool(temp[3].ord & 1)
		  @game[:random_races] = Convert.num2bool(temp[3].ord & 2)

		  if Convert.num2bool(temp[3].ord & 64)
			  @game[:observers] = Convert.observers(4)
		  end		

		  temp = temp[13..-1].split(0.chr)
		  @game[:creator] = temp[1]
		  @game[:map] = temp[0]
		
		  map_name = self.get_map_details(@game[:map])
		
		  @xml = Xml2dota.new(map_name)		


		  @game[:slots] =  @data.unpack("L")
		  @data = @data[4..-1]
		
		  @game[:type] = Convert.game_type(@data[0].ord)
		  @game[:private] = Convert.num2bool(@data[1].ord)


		  @data = @data[8..-1]

		  # Player List
		  while (@data[0] == "\x16") do
			  self.load_player!
			  @data = @data[4..-1]
		  end

		  # Game Start Record
		  @game[:record_id], @game[:record_length], @game[:slot_records] = @data.unpack("CSC")
		  @data = @data[4..-1]

		  slot_records = @game[:slot_records]

		  slot_records.times do |i|
			  temp = {}
			  temp[:player_id], temp[:slot_status], temp[:computer], temp[:team], temp[:color], temp[:race], temp[:ai_strength], temp[:handicap] = @data.unpack("Cx1CCCCCCC") 

			  temp[:color] = Convert.color(temp[:color])
			  temp[:ai_strength] = Convert.ai(temp[:ai_strength])
			  temp[:race] = Convert.race(temp[:race])

			  temp[:dota_id] = Convert.color2dotaid(temp[:color])
			  @dotaid2w3id[temp[:dota_id]] = temp[:player_id]

			  # TODO: Add support for computer players?
			  if temp[:slot_status] == 2 and temp[:computer] != 1
				
				  # Observers
				  if temp[:team] == 12
					  @players[temp[:player_id]] = @players[temp[:player_id]].merge(temp)
					  @observers[temp[:player_id]] = @players[temp[:player_id]]
				  else
					  @players[temp[:player_id]] = @players[temp[:player_id]].merge(temp)
				  end

				  @players[temp[:player_id]][:retraining_time] = 0
	
			  end

			  @data = @data[9..-1]


		  end


		  # 4.12 [RandomSeed]
		  temp = {}
		  temp[:random_seed], temp[:select_mode], temp[:start_spots] = @data.unpack("LCC")
		  @data = @data[6..-1]
		  @game[:random_seed] = temp[:random_seed]

		  @game[:select_mode] = Convert.select_mode(temp[:select_mode])

		  # Tournament replays from battle.net website don't have this info
		  if temp[:start_spots] != 0xCC
			  @game[:start_spots] = temp[:start_spots]
		  end
		
	  end



	  # 5.0 Replay Data Parsing
	  def parse_blocks!
		  data_left = @data.size

		  while(data_left > @max_datablock) do
			
			  prev = (defined?(block_id)) ? block_id : 1
			  block_id = @data[0].ord
			
			  case block_id

				  # TimeSlot Block
			  when 0x1E, 0x1F
				  temp = {}
				  temp[:length], temp[:time_inc] = @data.unpack("x1SS")
			
				  unless @paused
					  @time = @time + temp[:time_inc]
				  end

			
				  if temp[:length] > 2
					  self.parse_actions!(@data[5, (temp[:length]-2)], temp[:length]-2)
				  end

				  @data = @data[(temp[:length]+3)..-1]

				  data_left = data_left - (temp[:length]+3)


				  # Player chat
			  when 0x20
				  temp = {}
				  temp[:player_id], temp[:length], temp[:flags], temp[:mode] = @data.unpack("x1CSCS")
					
				  if temp[:flags] == 0x20
					  temp[:mode] = Convert.chat_mode(temp[:mode])
					  temp[:text] = @data[9, (temp[:length]-6)]
				  elsif temp[:flags] == 0x10
					  # Random messages
					  temp[:text] = @data[7, (temp[:length]-3)]
					  temp.delete(:mode)
				  end

				  @data = @data[(temp[:length]+4)..-1]
				  data_left = data_left - (temp[:length] + 4)

				  temp[:time] = Convert.time(@time)
				  temp[:player_name] = @players[temp[:player_id]][:name]
				  @chat << temp

			  when 0x22
				  temp = @data[1].ord
				  @data = @data[(temp+2)..-1]
				  data_left = data_left - (temp+2)
			
			  when 0x1A, 0x1B, 0x1C
				  @data = @data[5..-1]
				  data_left = data_left - 5
				
			  when 0x23
				  @data = @data[11..-1]
				  data_left = data_left - 11
		
			  when 0x2F
				  @data = @data[9..-1]
				  data_left = data_left - 9

				  # Leave game
			  when 0x17
				  @leaves = @leaves + 1
				
				  temp = {}
				  temp[:reason], temp[:player_id], temp[:result] ,temp[:unknown] = @data.unpack("x1LCLL")
				
				  @players[temp[:player_id]][:time] = @time
				  @players[temp[:player_id]][:leave_reason] = temp[:reason]
				  @players[temp[:player_id]][:leave_result] = temp[:result]
				
				  chat = {}
				  chat[:mode] = "QUIT"
				  chat[:text] = "Finished"



				  chat[:time] = @time
				  chat[:player_name] = @players[temp[:player_id]][:name]
				  @chat << chat				
				
				  @data = @data[14..-1]
				  data_left = data_left - 14

				  # TODO Add leaver code here

			  when 0
				  data_left = 0

			  else
				  raise "Error in block command. Block ID: #{block_id}"
				  exit										

			  end
			
		
		  end
	  end

	  def parse_actions!(action_block, data_length)
		  block_length = 0

		  while data_length > 0 do

			  if block_length
				  action_block = action_block[block_length..-1]
			  end
	
			  temp = {}
			  temp[:player_id], temp[:length] = action_block.unpack("CS")

			  @player_id = player_id = temp[:player_id]
			  block_length = temp[:length] + 3

			  data_length = data_length - block_length

			  was_deselect = false
			  was_subupdate = false


			  n = 3
			
			  while n < block_length do
				
				  prev = (defined? action) ? action : 0
				  action = action_block[n].ord
				

				  case action
					
				  # Unit / building ability (no additional parameters)
				  # Here we detect the various upgrades
				  when 0x10
					
					  # TODO: NB finish!

					  @players[player_id][:actions] << @time

					  # Newer versions, ability flag is 1 byte longer
					  if @header[:major_v] >= 13
						  n = n + 1
					  end

					  item_id = action_block[(n+2), 4].reverse!
					
					  value = Convert.item(item_id, @xml)
					
					  if !value
						  self.increment_action!(player_id, :ability)						
						  # Destroyers code removed - irrelevant to dota
					  else
						  self.increment_action!(player_id, :buildtrain)
						
						  unless @players[player_id][:race_detected]
							  @players[player_id][:race_detected] = Convert.race(item_id)
						  end
						
						
						  # Entity name and type
						  name = value.name
						  type = value.type
						
						  case type
							  when "hero"
								  if @in_pick_mode
									
									  # Handle duplicate actions
									  if @previous_pick and @previous_pick == name
										  next
									  end
									
									  value.extra = @players[player_id][:team]
									
									  # 3-2 ban split in CM mode of versions >= 6.68
									  if @game[:dota_major] == 6 and @game[:dota_minor] >= 68
										  if !@dota_mode.ban_phase_complete?
											  break
										  end
										
										  if @dota_mode.bans_per_team == 3
											  if @dota_mode.num_picks >= 6
												  break
											  end
										  end
										
										  @dota_mode.pick_hero!(value)
										  @num_picks += 1
								
									  # Otherwise old 4 ban version
									  else
										  if @num_bans > NUM_OF_BANS
											  break
										  end
										
										  @picks << value
										  @num_picks += 1
									  end
									
									  @previous_pick = value.name
									
									  if @num_picks >= NUM_OF_PICKS
										  @paused = false
										  @in_pick_mode = false
									  end
								
								  end # End in_pick_mode
								
							  when "skill", "ultimate", "stat"
								  # Get hero from related_to skill
								  hero_id = @xml.skill_to_hero_map[value.id]
								  hero_name = @xml.data_map[hero_id].name
								
								  pid = @players[player_id][:dota_id]
																
								  if !@stats[pid]
									  @preannounce_skill[pid] = {:skill_data => value, :time => @time, :hero_id => hero_id}

								  # Player is skilling, but no hero set yet.
					                    # Save the Skill Data and Time, and try to add the skill on cleanup
								  elsif !@stats[pid].is_hero_set?
									  @stats[pid].add_delayed_skill!(value, @time, hero_id)

								  # If skill-to-hero is the same as player's hero or common attribute skill the hero
								  elsif value.id == "A0NR" or hero_name == "Common" or hero_name == @stats[pid].hero.name
									  @stats[pid].hero.set_skill!(value, @time)

								  # Otherwise assume the player's skilling a Hero not owned by him
								  else
									  if @activated_heroes[hero_name]
										  @activated_heroes[hero_name].set_skill!(value, @time)
									  end								
								  end
								
							  when "item"
								  if (@time - @players[player_id][:last_time]) > ACTION_DELAY or @players[player_id][:last_itemid] != item_id
									  @players[player_id][:items][@time] = value
								  end
								
							  when "error"
								  raise "Error: unknown SkillID: #{value}"
							  else
								  raise "Unknown ItemID: #{value}."
								
						  end # End case
						
						  @players[player_id][:last_time] = @time
						  @players[player_id][:last_itemid] = item_id
						  
						
					  end

					  n = n+14

					  # Unit / building ability (with target position)
				  when 0x11
						
					  if @header[:major_v] >= 13
						  n = n+1
					  end
						
					  @players[player_id][:actions] << @time
						
					  if action_block[n+2].ord == 0x19 and action_block[n+3] == 0x00
						  self.increment_action!(player_id, :basic)
					  else
						  self.increment_action!(player_id, :ability)							
					  end
						
					
					  # Did not include building information.

					  n = n+22

					
					  # Unit / building ability with position and target object ID
				  when 0x12
						
					  if @header[:major_v] >= 13
						  n = n+1
					  end	
						
					  @players[player_id][:actions] << @time	
						
					  if action_block[n+2].ord == 0x03 and action_block[n+3].ord == 0x00
						  self.increment_action!(player_id, :rightclick)							
					  elsif action_block[n+2].ord <= 0x19 and action_block[n+3].ord == 0x00
						  self.increment_action!(player_id, :basic)
					  else
						  self.increment_action!(player_id, :ability)							
					  end

					  n = n+30

				  when 0x13
						
					  if @header[:major_v] >= 13
						  n = n+1
					  end
					
					  @players[player_id][:actions] << @time	
					
					  self.increment_action!(player_id, :item)
	
					  n = n+38

				  when 0x14
						
					  if @header[:major_v] >= 13
						  n = n+1
					  end		
						
					  @players[player_id][:actions] << @time	
						
					  if action_block[n+2].ord == 0x03 and action_block[n+3].ord == 0x00
						  self.increment_action!(player_id, :rightclick)							
					  elsif action_block[n+2].ord <= 0x19 and action_block[n+3].ord == 0x00
						  self.increment_action!(player_id, :basic)
					  else
						  self.increment_action!(player_id, :ability)							
					  end					

					  n = n+43

					  # Change selection
				  when 0x16


					  temp = {}
					  temp[:mode], temp[:num] = action_block[(n+1), 3].unpack("CS")

					  if temp[:mode] == 0x02 or !was_deselect
						  @players[player_id][:actions] << @time						

						  self.increment_action!(player_id, :select) 
					  end

					  was_deselect = (temp[:mode] == 0x02)

					  @players[player_id][:units_multiplier] = temp[:num]
					  n = n + 4 + (temp[:num]*8)

					  # Assign group hotkey
				  when 0x17
					  @players[player_id][:actions] << @time

					  self.increment_action!(player_id, :assignhotkey)
					
					  # Left out group hotkeys - irrelevant to DotA.

					  temp = {}
					  temp[:group], temp[:num] = action_block[(n+1), 3].unpack("CS")						
					  n = n + 4 + (temp[:num]*8)
	
					  # Select group hotkey
				  when 0x18
					  @players[player_id][:actions] << @time

					  self.increment_action!(player_id, :selecthotkey)

					  temp = {}
					  temp[:group], temp[:num] = action_block[(n+1), 3].unpack("CS")						
					  n = n + 3

					  # Select subgroup
				  when 0x19

					  if @header[:build_v] >= 6040 or @header[:major_v] > 14
						  if defined?(was_subgroup) and was_subgroup
							  self.increment_action!(player_id, :subgroup)
						  end
						  n = n+13
					  else
						  n = n+2
					  end

					  # Some sub action holder
				  when 0x1A
						
					  if @header[:build_v] >= 6040 or @header[:major_v] > 14
						  n = n+1
						  was_subgroup = (prev == 0x19 || prev == 0)
					  else
						  n = n+10
					  end

					  # Only in scenarios 
					  # version < 14b: select ground item
				  when 0x1B
						
					  if @header[:build_v] >= 6040 or @header[:major_v] > 14
						  n = n+10
					  else
						  @players[player_id][:actions] << @time
						  n = n+10
					  end

					  # Select ground item
					  # version < 14b: cancel hero revival
				  when 0x1C
						
					  if @header[:build_v] >= 6040 or @header[:major_v] > 14
						  @players[player_id][:actions] << @time
						  n = n+10
					  else
						  @players[player_id][:actions] << @time
						  n = n+9
					  end

					  # Cancel hero revival
					  # Remove unit from building queue
				  when 0x1D, 0x1E
						
					  if (@header[:build_v] >= 6040 or @header[:major_v] > 14) and action != 0x1E
						  @players[player_id][:actions] << @time
						  n = n+9
					  else
						  # TODO: Add non-dota related code for unit building cancellations. Not really important
						  @players[player_id][:actions] << @time
						  self.increment_action!(player_id, :removeunit)
						  n = n+6
					  end

            # Found in replays with patch version 1.04 and 1.05.
				  when 0x21
					  n = n+9;

					  # Adjust ally options
				  when 0x50
					  @players[player_id][:actions] << @time

					  self.increment_action!(player_id, :allyoptions)
					
					  n = n + 6

					  # Transfer resources
				  when 0x51
					  @players[player_id][:actions] << @time

					  self.increment_action!(player_id, :sendresources)
					
					  n = n + 10

				  # Map trigger chat commands (-ap etc)
				  # TODO: Maybe use this info?
				  when 0x60
					  n = n+9
				
					  str = ""
					  while(action_block[n] != 0.chr) do
						  str << action_block[n]
						  n = n+1
					  end
					
					  n = n + 1
						
				  # ESC Pressed
				  when 0x61
					  @players[player_id][:actions] << @time
					  self.increment_action!(player_id, :esc)
					  n = n+1

					  # Scenario trigger
					  # Removed version check as I do not allow replays with major_v < 7
				  when 0x62
					  n = n + 13

					
					  # Enter hero skill submenu
				  when 0x65, 0x66
					  @players[player_id][:actions] << @time
					  self.increment_action!(player_id, :heromenu)					
					  n = n + 1	

					  # Enter building submenu
				  when 0x67
					  @players[player_id][:actions] << @time
					  self.increment_action!(player_id, :buildmenu)					
					  n = n + 1	

					  # Map ping
				  when 0x68
					  @players[player_id][:actions] << @time
					  self.increment_action!(player_id, :signal)
					  n = n+13

					  # Continue game
				  when 0x69, 0x6A
					  @continue_game = true
					  n = n + 17

					  # Pause game
				  when 0x01
					  @paused = true
					  n = n+1

					  # Resume game
				  when 0x02
					  @paused = false
					  n = n+1

					  # Increase / decrease game speed
				  when 0x04, 0x05
					  n = n + 1

					  # Set game speed
				  when 0x03
					  n = n+2

					  # Save game
				  when 0x06
			
				
					  while(action_block[n] != 0.chr) do
						  n = n+1
					  end
					
					  @players[player_id][:actions] << @time
					  self.increment_action!(player_id, :save)
					  n = n+1



					  # Save game finished
				  when 0x07
					  n = n+5

					  # Only in scenarios
				  when 0x75
					  n = n+2


					  # Stored integer actions
				  when 0x6B

					  game_cache = ""
					  mission_key = ""
					  key = ""
					  value = ""

					  while (n < block_length and action_block[n] != 0.chr) do
						  game_cache << action_block[n]
						  n = n + 1
					  end	

					  n = n+1

					  while (n < block_length and action_block[n] != 0.chr) do
						  mission_key << action_block[n]
						  n = n+1
					  end	

					  n = n+1

					  while (n < block_length and action_block[n] != 0.chr) do
						  key << action_block[n]
						  n = n+1						
					  end	

					  n = n + 1
					  # In the case of the Key being 8, we're dealing with items, so we get the Item information as an object
            # In the case of the Key being 9, we're dealing with heroes, so we get the Hero information as an object
					  if  key[0] == "8" or key == "9"
						  value = action_block[n, 4].reverse
						
						  if value == "\0\0\0\0"
							  value = 0
						  else
							  value = Convert.item(value, @xml)					
						  end
						
					  # Otherwise value holds the raw string
					  else
						  value = action_block[n, 4].unpack("L")
					  end

					  if mission_key == "Data"
							  # These all use the slot id and not dota ID
							  # POTM Arrows
							  if key =~ /AA_Total([0-9]{1,2})/
								  pid = @slot_to_player_map[$1.to_i]
								  if @stats[pid]
									  @stats[pid].aa_total = value
								  end
							  elsif key =~ /AA_Hits([0-9]{1,2})/								
								  pid = @slot_to_player_map[$1.to_i]
								  if @stats[pid]
									  @stats[pid].aa_hits = value
								  end								
							  #Pudge Hooks
							  elsif key =~ /HA_Total([0-9]{1,2})/
								  pid = @slot_to_player_map[$1.to_i]
								  if @stats[pid]
									  @stats[pid].ha_total = value
								  end
							  elsif key =~ /HA_hits([0-9]{1,2})/
								  pid = @slot_to_player_map[$1.to_i]
								  if @stats[pid]
									  @stats[pid].ha_hits = value
								  end
							  # Runes
							  elsif key =~ /RuneUse([0-9]{1,2})/
								  pid = @slot_to_player_map[value]
								  if @stats[pid]
									  @stats[pid].runes_used += 1
								  end								
							  end	
							


							  # Detect mode
							  if key.include?("Mode")
								  short_mode = key[4, 2]
								
								  case short_mode
									  when "cm"
										  @dota_mode = CMMode.new
									  when "cd"
										  @dota_mode = CDMode.new
								  end
							  end
						
					  end
					
					  # CD Mode broadcasting seems to be broken
					  # TODO: Finish this if statement
					  if @dota_mode and @dota_mode.short_name == "cd"

						
					  # Continue with CM ban / pick then
					  elsif key.include?("Ban")
						  unless @in_pick_mode
							  @in_pick_mode = true
							  @paused = true
						  end
						
						  entity_id = action_block[n,4].reverse
						  entity = Convert.item(entity_id, @xml)
						
						  if @slot_to_player_map[key[3]]
							  team_pid = @slot_to_player_map[key[3]]
						  else
							  team_pid = key[3]
						  end
						
						  if key == "Ban1"
							  entity.extra = 0
						  elsif key == "Ban7"
							  entity.extra = 1
						  else
							  entity.extra = @players[team_pid][:team]
						  end
						
						  # 3-2 ban split CM mode from version >= 6.68
						  if @game[:dota_major] == 6 and @game[:dota_minor] >= 68
							  # If we've already got all bans for phase 1 (6 bans) and we get a new ban action, 
                # then we need to start phase 2
							  if @dota_mode.ban_phase_complete?
								  @dota_mode.bans_per_team = 5
							  end
							
							  @dota_mode.ban_hero!(entity)
						  else
							
							  @bans << entity
							  @num_bans +=1
						  end
						
						
					  # Get the winner from a finished game
					  elsif mission_key == "Global" and key == "Winner"						
						  @extra[:parsed_winner] = (value == 1) ? "Sentinel" : "Scourge"
					  end

					  # Hero assignment and stats collecting
					  if is_numeric?(mission_key) and mission_key.to_i > -1 and mission_key.to_i < 13
						  mission_key = mission_key.to_i
						  # Map slot ID to the proper player ID
						  if @slot_to_player_map[mission_key]
							  pid = @slot_to_player_map[mission_key]
						  else
							  pid = mission_key
						  end 
						
						  # Set heroes for players, including swap & repick handling
						  if key == "9"

							  # Failsafe
							  if @in_pick_mode
								  @in_pick_mode = false
								  @paused = false
							  end
							
							  x_pid = pid
							  x_hero = value

							  # No hero picked
							  if !x_hero.is_a?(Hero)
								
								  # Handle? - TODO								
							  # If hero is picked before player IDs are sent out
							  elsif !@stats[x_pid]
								  @preannounce_pick[x_pid] = x_hero
								
							  # Set hero for player if player's hero ain't set yet
							  elsif !@stats[x_pid].is_hero_set?
								  @stats[x_pid].hero = ActivatedHero.new(x_hero)
								  @activated_heroes[x_hero.name] = @stats[x_pid].hero
								
							  # Players are either swapping or repicking or hero-replaced at the end
							  else
								  # If the Hero's already been Activated either swapping or end game's taking place
								  if @activated_heroes[x_hero.name]
									  # Swapping taking place
									  if @stats[x_pid].hero.name != x_hero.name
										  @stats[x_pid].hero = @activated_heroes[x_hero.name]
										
									  # else end game stats
									  else
										  # TODO - handle stats?
									  end
								  # Hero-replacement ( Ezalor, etc) or repicking's taking place
								  else
									
									  # If the name matches we're dealing with a morphing ability, otherwise it's repicking
									  if @stats[x_pid].hero.name != x_hero.name
										  # Assign as player's new hero
										  @stats[x_pid].hero = ActivatedHero.new(x_hero)
										
										  # Add to activated list
										  @activated_heroes[x_hero.name] = @stats[x_pid].hero
									  end
								  end
							  end

							
						  end
						

							
						  # Stats collecting
						  case key[0]
							

							  when "i" #ID
								  # Value seems to be in array form
								  pid = value.first
								
								  @slot_to_player_map[mission_key] = pid
								
								  # For handling SP
								  @translated_dotaid[pid] = mission_key
								
								  unless @stats[pid]
									
									  # NB: Stats are stored by DotA ID's and not w3 id's
									  @stats[pid] = PlayerStats.new(pid)

									  # Check if there's any pending delayed hero for the player
									  if @preannounce_pick[mission_key]
										  x_hero = @preannounce_pick[mission_key]
										  @stats[pid].hero = ActivatedHero.new(x_hero)
										
										  @activated_heroes[x_hero.name] = @stats[pid].hero
									  end
									
									  # Check if there's any pending delayed skilling for the player
									  if @preannounce_skill[pid]
										  @stats[pid].add_delayed_skill!(
											  @preannounce_skill[pid][:skill_data],
											  @preannounce_skill[pid][:time],
											  @preannounce_skill[pid][:hero_id]
										  )
									  end
								  end
								
							  when "1"
								  @stats[pid].kills = value.first
							  when "2"
								  @stats[pid].deaths = value.first
							  when "3"
								  @stats[pid].creep_kills = value.first	
							  when "4"
								  @stats[pid].creep_denies = value.first
							  when "5"
								  @stats[pid].assists = value.first
							  when "6"
								  @stats[pid].end_gold = value.first	
							  when "7"
								  @stats[pid].neutrals = value.first
							  # Inventory
							  when "8"
								  @stats[pid].inventory[key[2]] = value								
							
						  end # end case
						
					  end
					
					
					
					  n = n + 4


					  # No idea - Labelled "Add seven"
				  when 0x70
					  n = n+28

				  else

					  raise "Unknown action: #{action}, prev: #{prev}, player name: #{@players[player_id][:name]}\n"
					  n = n+2
									

				  end

			  end
			
			  was_deselect = (action == 0x16)
			  was_subupdate = (action == 0x19)
		  end
	  end

	  def cleanup!
		
		  if @dota_mode
			  @bans = (@bans.size > 0) ? @bans : @dota_mode.hero_bans
			  @picks = (@picks.size > 0) ? @picks : @dota_mode.hero_picks
		  end
		
		  @num_bans = @bans.size
		  @num_picks = @picks.size
		
		  # Process delayed skills
		  @stats.each do |pid, player|
			  player.process_delayed_skills!
		  end

		# TODO: Add remaining cleanup code for handling player switch.
		
	  end





	  def inflate(data)
		  zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
		  buf = zstream.inflate(data)
		  zstream.finish
		  zstream.close
		  buf
	  end

	  def true?(value)
		  return (!value) ? false : true
	  end
	
	  def is_numeric?(value)
			  Float(value) != nil rescue false	
	  end
	
	  def increment_action!(player_id, action)
		  action = action.to_s
		  if @players[player_id][:actions_details][Convert.action(action)]
			  @players[player_id][:actions_details][Convert.action(action)] = @players[player_id][:actions_details][Convert.action(action)] + 1
		  else
			  @players[player_id][:actions_details][Convert.action(action)] = 1
		  end			
	  end

	  def get_map_details(map_name)
		
		  # Strip the directories and extension off the file name
		  map_name = map_name[(map_name.rindex("\\")+1..-1)]
		  map_name = map_name[0..-5]

		  matches = /([0-9]{1,1})\.([0-9]{1,2})([a-zA-Z]{0,1})/.match(map_name)
		
		  unless matches
			raise "Not a DotA replay."
		  end

		  # Use the default map if we cannot determine which map it is
		  if matches.size < 4
			  return DEFAULT_XML_MAP
		  else
			  @game[:dota_major] = matches[1].to_i
			  @game[:dota_minor] = matches[2].to_i
			  @game[:dota_subversion] = matches[3].to_i
			

			  # Check if file version exists
			  if File.exists?("#{MAPS_FOLDER}/#{XML_MAP_BASE_NAME}#{@game[:dota_major]}.#{@game[:dota_minor]}#{@game[:dota_subversion]}.xml")
				  "#{MAPS_FOLDER}/#{XML_MAP_BASE_NAME}#{@game[:dota_major]}.#{@game[:dota_minor]}#{@game[:dota_subversion]}.xml"
				
			  # Otherwise check if file version without the subversion (e.g. b, c, d...) exists
			  elsif File.exists?("#{MAPS_FOLDER}/#{XML_MAP_BASE_NAME}#{@game[:dota_major]}.#{@game[:dota_minor]}.xml")
				  "#{MAPS_FOLDER}/#{XML_MAP_BASE_NAME}#{@game[:dota_major]}.#{@game[:dota_minor]}.xml"
				
			  # Do not support maps older then 6.59
			  elsif @game[:dota_major] < 6 || (@game[:dota_major] == 6 and @game[:dota_minor] < 59)
				  raise "Unsupported map version."
				  false
			  else
			  # Otherwise use the default map
				  DEFAULT_XML_MAP				
			  end
		  end
		
	  end

  end
end
