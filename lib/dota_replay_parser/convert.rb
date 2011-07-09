class Convert

	def self.speed(value)
		case value
		when 1
			"Slow"
		when 2
			"Normal"
		when 3
			"Fast"
		end
	end

	def self.visibility(value)
		case value
		when 0
			'Hide Terrain'
		when 1
			'Map Explored'
		when 2
			'Always Visible'
		when 3
			'Default'
		end
	end

	def self.observers(value)
		case value
		when 0 
			'No Observers'
		when 2
			'Observers On'
		when 3
			'Full Observers'
		when 4
			'Referees'
		end
	end

	def self.bool2num(value)
		if value
			1
		else
			0
		end
	end

	def self.num2bool(value)
		return (value == 0) ? false : true
	end

	def self.color(value)

 		case value
		when 0
			"red"
		when 1 
			"blue"
		when 2 
			"teal"
		when 3 
			"purple"
		when 4 
			"yellow"
		when 5 
			"orange"
		when 6 
			"green"
		when 7 
			"pink"
		when 8 
			"gray"
		when 9 
			"lightblue"
		when 10 
			"darkgreen"
		when 11
			"brown"
		when 12 
			"observer"
		end

	end

	def self.race(value)
		case value
			when "ewsp", 4, 0x44
				"Sentinel"
			when "uaco", 8, 0x48
				"Scourge"
			else
				0
		end
	end

	def self.ai(value)
		case value
			when 0x00
				"Easy"
			when 0x01
				"Normal"
			when 0x02
				"Insane"
		end
	end


	def self.select_mode(value)
		case value
			when 0x00
				"Team & race selectable"
			when 0x01
				"Team not selectable"
			when 0x03
				"Team & race not selectable"
			when 0x04
				"Race fixed to random"
			when 0xcc
				"Automated Match Making (ladder)"
		end			
	end

	def self.chat_mode(value)
		case value
			when 0x00
				0		# All
			when 0x01
				1		# Allies
			when 0x02
				2		# Observers
			when 0xFE
				3		# Game paused
			when 0xFF
				4		# Game resumed
			else
				value-2 	# PVT
		end
	end

	def self.action(value)
		case value
			when "rightclick"
				"Right click"
			when "select"
				"Select / deselect"
			when "selecthotkey"
				"Select group hotkey"
			when "assignhotkey"
				"Assign group hotkey"
			when "ability"
				"Use ability"
			when "basic"
				"Basic commands"
			when "buildtrain"
				"Build / train"
			when "buildmenu"
				"Enter build submenu"
			when "subgroup"
				"Enter subgroup"
			when "heromenu"
				"Enter hero's abilities submenu"
			when "item"
				"Give / drop item"
			when "removeunit"
				"Remove unit from queue"
			when "esc"
				"ESC pressed"
			when "allyoptions"
				"Adjust ally options"
			when "sendresources"
				"Transfer resources"
			when "signal"
				"Minimap ping"
			when "save"
				"Save game"
		end
	end

	def self.game_type(value)
		case value
			when 0x01
				"Ladder 1vs1/FFA"
			when 0x09
				"Custom game"
			when 0x0D
				"Single player/Local game"
			when 0x20
				"Ladder team game (AT/RT)"
			else
				"Unknown"
		end	
	end
	
	def self.color2dotaid(value)
		case value

			when "blue"
				1
			when "teal"
				2
			when "purple"
				3
			when "yellow"
				4
			when "orange"
				5
			when "pink"
				6
			when "gray"
				7
			when "lightblue"
				8
			when "darkgreen"
				9
			when "brown"
				10
			else
				0

		end
	end
	
	def self.item(value, xml)
				if value.empty? || !(xml.data_map[value])
					false
				else
					xml.data_map[value]
				end
	end
	
	def self.time(value)
		minutes = sprintf("%02d", value / 60000)
		seconds = sprintf("%02d", (value % 60000)/1000)
		
		"#{minutes}:#{seconds}"
	end

	
end