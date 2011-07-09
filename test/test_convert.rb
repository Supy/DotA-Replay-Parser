require File.join(File.dirname(File.expand_path(__FILE__)), 'helper')

class TestConvert < Test::Unit::TestCase
  def test_speed
    assert_equal nil, DotaReplayParser::Convert.speed(0)
    assert_equal 'Slow', DotaReplayParser::Convert.speed(1)
    assert_equal 'Normal', DotaReplayParser::Convert.speed(2)
    assert_equal 'Fast', DotaReplayParser::Convert.speed(3)
    assert_equal nil, DotaReplayParser::Convert.speed(4)
  end
  
  def test_visibility
    assert_equal 'Hide Terrain', DotaReplayParser::Convert.visibility(0)
    assert_equal 'Map Explored', DotaReplayParser::Convert.visibility(1)
    assert_equal 'Always Visible', DotaReplayParser::Convert.visibility(2)
    assert_equal 'Default', DotaReplayParser::Convert.visibility(3)
    assert_equal nil, DotaReplayParser::Convert.visibility(4)
  end
  
  def test_observers
    assert_equal 'No Observers', DotaReplayParser::Convert.observers(0)
    assert_equal 'Observers On', DotaReplayParser::Convert.observers(1)
    assert_equal 'Full Observers', DotaReplayParser::Convert.observers(2)
    assert_equal 'Referees', DotaReplayParser::Convert.observers(3)
  end
  
  def test_bool2num
    assert_equal 1, DotaReplayParser::Convert.bool2num(true)
    assert_equal 0, DotaReplayParser::Convert.bool2num(false)
  end
  
  def test_num2bool
    assert_equal false, DotaReplayParser::Convert.num2bool(0)
    assert_equal true, DotaReplayParser::Convert.num2bool(1)
    assert_equal true, DotaReplayParser::Convert.num2bool(-1)
  end
  
  def test_color
    assert_equal 'red', DotaReplayParser::Convert.color(0)
    assert_equal 'blue', DotaReplayParser::Convert.color(1)
    assert_equal 'teal', DotaReplayParser::Convert.color(2)
    assert_equal 'purple', DotaReplayParser::Convert.color(3)
    assert_equal 'yellow', DotaReplayParser::Convert.color(4)
    assert_equal 'orange', DotaReplayParser::Convert.color(5)
    assert_equal 'green', DotaReplayParser::Convert.color(6)
    assert_equal 'pink', DotaReplayParser::Convert.color(7)
    assert_equal 'gray', DotaReplayParser::Convert.color(8)
    assert_equal 'lightblue', DotaReplayParser::Convert.color(9)
    assert_equal 'darkgreen', DotaReplayParser::Convert.color(10)
    assert_equal 'brown', DotaReplayParser::Convert.color(11)
    assert_equal 'observer', DotaReplayParser::Convert.color(12)
  end
  
  def test_race
    assert_equal 0, DotaReplayParser::Convert.race('asian')
    assert_equal 0, DotaReplayParser::Convert.race(1)
    assert_equal 'Sentinel', DotaReplayParser::Convert.race('ewsp')
    assert_equal 'Sentinel', DotaReplayParser::Convert.race(4)
    assert_equal 'Sentinel', DotaReplayParser::Convert.race(0x44)
    assert_equal 'Scourge', DotaReplayParser::Convert.race('uaco')
    assert_equal 'Scourge', DotaReplayParser::Convert.race(8)
    assert_equal 'Scourge', DotaReplayParser::Convert.race(0x48)
  end
  
  def test_ai
    assert_equal 'Easy', DotaReplayParser::Convert.ai(0x00)
    assert_equal 'Normal', DotaReplayParser::Convert.ai(0x01)
    assert_equal 'Insane', DotaReplayParser::Convert.ai(0x02)
  end
  
  def test_select_mode
    assert_equal 'Team & race selectable', DotaReplayParser::Convert.select_mode(0x00)
    assert_equal 'Team not selectable', DotaReplayParser::Convert.select_mode(0x01)
    assert_equal 'Team & race not selectable', DotaReplayParser::Convert.select_mode(0x03)
    assert_equal 'Race fixed to random', DotaReplayParser::Convert.select_mode(0x04)
    assert_equal 'Automated Match Making (ladder)', DotaReplayParser::Convert.select_mode(0xcc)
  end
  
  def test_chat_mode
    assert_equal 0, DotaReplayParser::Convert.chat_mode(0x00)
    assert_equal 1, DotaReplayParser::Convert.chat_mode(0x01)
    assert_equal 2, DotaReplayParser::Convert.chat_mode(0x02)
    assert_equal 3, DotaReplayParser::Convert.chat_mode(0xFE)
    assert_equal 4, DotaReplayParser::Convert.chat_mode(0xFF)
    assert_equal 0x0C, DotaReplayParser::Convert.chat_mode(0x0E)
  end
  
  def test_action
    assert_equal 'Right click', DotaReplayParser::Convert.action('rightclick')
    assert_equal 'Select / deselect', DotaReplayParser::Convert.action('select')
    assert_equal 'Select group hotkey', DotaReplayParser::Convert.action('selecthotkey')
    assert_equal 'Assign group hotkey', DotaReplayParser::Convert.action('assignhotkey')
    assert_equal 'Use ability', DotaReplayParser::Convert.action('ability')
    assert_equal 'Basic commands', DotaReplayParser::Convert.action('basic')
    assert_equal 'Build / train', DotaReplayParser::Convert.action('buildtrain')
    assert_equal 'Enter build submenu', DotaReplayParser::Convert.action('buildmenu')
    assert_equal 'Enter subgroup', DotaReplayParser::Convert.action('subgroup')
    assert_equal 'Enter hero\'s abilities submenu', DotaReplayParser::Convert.action('heromenu')
    assert_equal 'Give / drop item', DotaReplayParser::Convert.action('item')
    assert_equal 'Remove unit from queue', DotaReplayParser::Convert.action('removeunit')
    assert_equal 'ESC pressed', DotaReplayParser::Convert.action('esc')
    assert_equal 'Adjust ally options', DotaReplayParser::Convert.action('allyoptions')
    assert_equal 'Transfer resources', DotaReplayParser::Convert.action('sendresources')
    assert_equal 'Minimap ping', DotaReplayParser::Convert.action('signal')
    assert_equal 'Save game', DotaReplayParser::Convert.action('save')
  end
  
  def test_game_type
    assert_equal 'Ladder 1vs1/FFA', DotaReplayParser::Convert.game_type(0x01)
    assert_equal 'Custom game', DotaReplayParser::Convert.game_type(0x09)
    assert_equal 'Single player/Local game', DotaReplayParser::Convert.game_type(0x0D)
    assert_equal 'Ladder team game (AT/RT)', DotaReplayParser::Convert.game_type(0x20)
    assert_equal 'Unknown', DotaReplayParser::Convert.game_type(0x02)
  end
  
  def test_color2dotaid
    assert_equal 1, DotaReplayParser::Convert.color2dotaid('blue')
    assert_equal 2, DotaReplayParser::Convert.color2dotaid('teal')
    assert_equal 3, DotaReplayParser::Convert.color2dotaid('purple')
    assert_equal 4, DotaReplayParser::Convert.color2dotaid('yellow')
    assert_equal 5, DotaReplayParser::Convert.color2dotaid('orange')
    assert_equal 6, DotaReplayParser::Convert.color2dotaid('pink')
    assert_equal 7, DotaReplayParser::Convert.color2dotaid('gray')
    assert_equal 8, DotaReplayParser::Convert.color2dotaid('lightblue')
    assert_equal 9, DotaReplayParser::Convert.color2dotaid('darkgreen')
    assert_equal 10, DotaReplayParser::Convert.color2dotaid('brown')
    assert_equal 0, DotaReplayParser::Convert.color2dotaid('observer')
  end
  
  def test_item
    skip
  end
  
  def test_time
    skip
  end
end
