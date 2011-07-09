module DotaReplayParser
  class Convert

	  SPEED = [nil, 'Slow', 'Normal', 'Fast']
	  def self.speed(value)
		  SPEED[value]
	  end

	  VISIBILITY = ['Hide Terrain', 'Map Explored', 'Always Visible', 'Default']
	  def self.visibility(value)
		  VISIBILITY[value]
	  end

	  OBSERVERS = ['No Observers', 'Observers On', 'Full Observers', 'Referees']
	  def self.observers(value)
		  OBSERVERS[value]
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

	  COLOR = ['red', 'blue', 'teal', 'purple', 'yellow', 'orange', 'green', 'pink', 'gray', 'lightblue', 'darkgreen', 'brown', 'observer']
	  def self.color(value)
	    COLOR[value]
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

	  AI = ['Easy', 'Normal', 'Insane']
	  def self.ai(value)
	    AI[value]
	  end


	  def self.select_mode(value)
		  case value
			when 0x00
			  'Team & race selectable'
			when 0x01
			  'Team not selectable'
			when 0x03
			  'Team & race not selectable'
			when 0x04
			  'Race fixed to random'
			when 0xcc
			  'Automated Match Making (ladder)'
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

	  ACTION = {
	    'rightclick'    => 'Right click',
	    'select'        => 'Select / deselect',
	    'selecthotkey'  => 'Select group hotkey',
	    'assignhotkey'  => 'Assign group hotkey',
	    'ability'       => 'Use ability',
	    'basic'         => 'Basic commands',
	    'buildtrain'    => 'Build / train',
	    'buildmenu'     => 'Enter build submenu',
	    'subgroup'      => 'Enter subgroup',
	    'heromenu'      => 'Enter hero\'s abilities submenu',
	    'item'          => 'Give / drop item',
	    'removeunit'    => 'Remove unit from queue',
	    'esc'           => 'ESC pressed',
	    'allyoptions'   => 'Adjust ally options',
	    'sendresources' => 'Transfer resources',
	    'signal'        => 'Minimap ping',
	    'save'          => 'Save game',
	  }
	  def self.action(value)
		  ACTION[value]
	  end

	  def self.game_type(value)
		  case value
			when 0x01
			  'Ladder 1vs1/FFA'
			when 0x09
			  'Custom game'
			when 0x0D
			  'Single player/Local game'
			when 0x20
			  'Ladder team game (AT/RT)'
			else
			  'Unknown'
		  end	
	  end
	
	  COLOR_TO_DOTA_ID = {
	    'blue'      => 1,
	    'teal'      => 2,
	    'purple'    => 3,
	    'yellow'    => 4,
	    'orange'    => 5,
	    'pink'      => 6,
	    'gray'      => 7,
	    'lightblue' => 8,
	    'darkgreen' => 9,
	    'brown'     => 10,
	  }
	  def self.color2dotaid(value)
		  COLOR_TO_DOTA_ID[value] || 0
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
end
