--  
--   ////\\\\
--   ////\\\\  MONITOR
--   ////\\\\  BY NEAUOIRE
--   \\\\////
--   \\\\////  MIDI SEQUENCER
--   \\\\////
--

local midi_signal_in
local midi_signal_out
local viewport = { width = 128, height = 64, frame = 0 }
local root = 60
local pattern = { length = 6, cells = {} }
local focus = { id = 1, sect = 1, is_playing= true }

-- Main

function init()
  connect()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Create Cells
  reset_cells()
  -- Render
  redraw()
end

function connect()
  midi_signal_in = midi.connect(1)
  midi_signal_in.event = on_midi_event
  midi_signal_out = midi.connect(2)
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  tab.print(msg)
  redraw()
end

function run()
  if focus.is_playing ~= true then return end
  focus.id = (viewport.frame % pattern.length) + 1
  viewport.frame = viewport.frame + 1
  redraw()
end

function get_mod()
  return 1
end

function get_input()
  return root
end

function get_output()
  return 61
end

function reset_cells()
  pattern.cells = {}
  pattern.cells[1]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[2]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[3]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[4]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[5]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[6]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[7]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[8]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[9]  = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[10] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[11] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[12] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[13] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[14] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[15] = { sect = 1, content = { 0,0,0,0 } }
  pattern.cells[16] = { sect = 1, content = { 0,0,0,0 } }
  mod_cell(2)
end

function set_cell(id,content)
  pattern.cells[id].content = content
end

function get_mod(id,sect)
  return pattern.cells[id].content[sect]
end

function mod_cell(id,sect,size)
  pattern.cells[id].sect = 2
  pattern.cells[id].content[1] = 1
  pattern.cells[id].content[2] = 1
  pattern.cells[id].content[3] = 2
  pattern.cells[id].content[4] = 2
end

-- Interactions

function key(id,state)
  redraw()
end

function enc(id,delta)
  if id == 1 then
    pattern.length = clamp(pattern.length + delta, 1, 16)
  end
  redraw()
end

-- Render

function draw_cell_content(id,sect,x,y)
  screen.level(15)
  screen.pixel((x+(sect*2))-1,y+7-get_mod(id,sect))
  screen.pixel((x+(sect*2))-2,y+7-get_mod(id,sect))
  screen.fill()
end

function draw_cell(id,x,y)
  if (id-1) >= pattern.length then return end
  x = (id-1) % 4
  y = math.floor((id-1) / 4)
  _x = (x * 9) + 3 + 8
  _y = (y * 9) + 7 + 8
  -- Background
  if id == focus.id then
    screen.level(1)
    screen.rect(_x,_y,8,8)
    screen.fill()
  end
  -- Content
  for sect = 1,4 do
    draw_cell_content(id,sect,_x,_y)
  end
end

function draw_sequencer()
  for id = 1,16 do
    draw_cell(id)
  end
end

function draw_labels()
  _input = get_input()
  _output = get_output()
  screen.level(15)
  screen.move(60,22)
  screen.text('?')
  screen.move(60,31)
  screen.text('hello')
  screen.move(60,40)
  screen.text(focus.id)
  
  note = get_output()
  screen.move(60,49)
  screen.text(note_to_format(_input)..' > '..note_to_format(_output))
end

function redraw()
  screen.clear()
  draw_sequencer()
  draw_labels()
  screen.update()
end

-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

function note_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

function note_to_name(number)
  id = number % 12
  names = {}
  names[0] = 'C'
  names[1] = 'C#'
  names[2] = 'D'
  names[3] = 'D#'
  names[4] = 'E'
  names[5] = 'F'
  names[6] = 'F#'
  names[7] = 'G'
  names[8] = 'G#'
  names[9] = 'A'
  names[10] = 'A#'
  names[11] = 'B'
  return names[id]
end

function note_to_octave(number)
  return math.floor(number / 12)
end

function note_to_format(number)
  return note_to_name(number)..''..note_to_octave(number)
end

-- Timer

re = metro.init()
re.time = 0.25
re.event = function()
  run()
end
re:start()