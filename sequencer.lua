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

local viewport = { w = 128, h = 64, frame = 1 }
local pattern = { root = 60, length = 8, max_length = 8, cells = { {0},{0},{0},{0},{0},{0},{0},{0} } }
local focus = { id = 1, sect = 1, mode = 0 }
local playhead = { id = 1, sect = 1, is_playing = true, bpm = 120 }
local template = { size = { w = 12, h = 24 }, offset = { x = 8, y = 30 } }
local last_key = nil

-- Main

function init()
  connect()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Create Cells
  set_bpm(120)
  re:start()
end

function run()
  if playhead.is_playing ~= true then return end
  playhead.id = (viewport.frame % pattern.length) + 1
  playhead.sect = get_sect(playhead.id)+1
  redraw()
end

-- Midi

function connect()
  midi_signal_in = midi.connect(1)
  midi_signal_in.event = on_midi_event
  midi_signal_out = midi.connect(2)
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  pattern.root = msg.note
end

function release_note()
  if last_note == nil then return end
  midi_signal_out:note_off(last_note,127,1)
  last_note = nil
end

function send_note()
  if last_note ~= nil then release_note() ; return end
  if get_output() == nil then return end
  midi_signal_out:note_on(get_output(),127,1)
  last_note = get_output()
end

-- Commands

function set_bpm(bpm)
  sec = 60 / (bpm*2)
  re.time = sec
end

function mod_pattern_length(delta)
  pattern.length = clamp(pattern.length + delta, 1, pattern.max_length)
  focus.id = clamp(focus.id,1,pattern.length)
  focus.sect = 1
end

function mod_focus(delta)
  if (focus.sect == #get_cell(focus.id) and delta > 0) or (focus.sect == 1 and delta < 0) then
    focus.id = clamp(focus.id + delta,1, pattern.length)
    focus.sect = clamp(focus.sect, 1, #get_cell(focus.id))
  else
    focus.sect = clamp(focus.sect + delta, 1, #get_cell(focus.id))
  end
end

function mod_sect(id,sect,delta)
  pattern.cells[id][sect] = clamp(pattern.cells[id][sect] + delta,-13,12)
end

function mod_bpm(delta)
  playhead.bpm = playhead.bpm + delta
  set_bpm(playhead.bpm)
end

function mod_length(delta)
  current = #pattern.cells[focus.id]
  if delta == 1 then
    if current == 1 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1], pattern.cells[focus.id][1] }
    elseif current == 2 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1], pattern.cells[focus.id][2], pattern.cells[focus.id][1] }
    elseif current == 3 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1], pattern.cells[focus.id][2], pattern.cells[focus.id][1], pattern.cells[focus.id][2] }
    end
  end
  if delta == -1 then
    if current == 4 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1], pattern.cells[focus.id][2], pattern.cells[focus.id][1] }
    elseif current == 3 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1], pattern.cells[focus.id][2] }
    elseif current == 2 then
      pattern.cells[focus.id] = { pattern.cells[focus.id][1] }
    end
  end
  focus.id = clamp(focus.id,1, pattern.length)
  focus.sect = clamp(focus.sect, 1, #get_cell(focus.id))
end

-- Helpers

function get_cell(id)
  return pattern.cells[id]
end

function get_sect(id)
  return math.floor(viewport.frame/pattern.length/id) % #get_cell(id)
end

function get_mod(id,sect)
  id = id or playhead.id
  sect = sect or playhead.sect
  return get_cell(id)[sect]
end

function get_input()
  return pattern.root
end

function get_output()
  if get_mod() == -13 then return nil end
  return note_offset(get_input(),get_mod())
end

function get_overall_length()
  sum = pattern.length
  for id = 1,pattern.length do
    sum = sum * #get_cell(id)
  end
  return sum
end

function get_overall_position()
  return (viewport.frame % get_overall_length()) + 1
end

-- Interactions

function key(id,state)
  -- Swap modes
  if state == 0 then
    focus.mode = 0
  else
    focus.mode = id
  end
  redraw()
end

function enc(id,delta)
  if focus.mode == 2 then
    mod_bpm(delta)
    redraw()
    return
  end
  if focus.mode == 3 then
    mod_length(delta)
    redraw()
    return
  end
  if id == 1 then mod_pattern_length(delta) end
  if id == 2 then mod_focus(delta) end
  if id == 3 then mod_sect(focus.id,focus.sect,delta) end
  redraw()
end

-- Render

function draw_sequencer()
  for id = 1,pattern.length do
    _x = ((id-1) * (template.size.w+2)) + template.offset.x
    _y = template.offset.y
    cell_w = 12/#get_cell(id)
    -- Grid
    screen.level(5)
    screen.pixel(_x,template.offset.y + 15)
    screen.fill()
    -- Cell
    for sect_id = 1,#get_cell(id) do 
      if playhead.id == id and playhead.sect == sect_id then screen.level(15) else screen.level(5) end
      if get_sect(id)+1 ~= sect_id then screen.level(1) end
      if get_mod(id,sect_id) == -13 then screen.level(0) end
      screen.rect(_x + ((sect_id-1) * cell_w),template.offset.y - get_mod(id,sect_id),cell_w,2)
      screen.fill()
    end
    -- Focus
    if id == focus.id then 
      screen.level(15)
      screen.pixel(_x + ((focus.sect-1) * cell_w),template.offset.y + 15)
      screen.move(_x + ((focus.sect-1) * cell_w)-1,54)
      screen.text('^')
      screen.text(delta_format(get_mod(focus.id,focus.sect)))
    end
    screen.fill()
  end
  -- Track Progress
  progress = (position/length)
  width = (pattern.length * (template.size.w+2))-2
  to = progress * width
  for x=1,width do
    screen.level(5)
    if to > x and x % 2 == 0 then 
      screen.pixel(template.offset.x+x,template.offset.y + 15)
    end
    screen.fill()
  end
end

function draw_labels()
  -- Slow
  position = get_overall_position()
  length = get_overall_length()
  incoming = note_to_format(get_input())
  offset = get_mod(playhead.id,playhead.sect)
  outgoing = note_to_format(get_output())
  screen.level(15)
  -- Input Offset Output
  screen.move(template.offset.x+104,16)
  if offset ~= 0 then
    screen.text_right(incoming..' '..delta_format(offset)..' '..outgoing)
  else
    screen.text_right(outgoing)
  end
  -- Top Left
  if focus.mode == 0 then
    screen.move(template.offset.x+1,16)
    if length > 2048 then
      screen.text(position)
    else
      screen.text(position..'/'..length)
    end
  elseif focus.mode == 2 then
    screen.move(template.offset.x+1,16)
    screen.text('BPM')
    screen.move(template.offset.x+27,16)
    screen.text(playhead.bpm)
  elseif focus.mode == 3 then
    screen.move(template.offset.x+1,16)
    screen.text('DIV')
    screen.move(template.offset.x+27,16)
    screen.text(#get_cell(focus.id))
  end
end

function redraw()
  screen.clear()
  draw_labels()
  draw_sequencer()
  screen.update()
end

-- Utils

function note_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

function note_offset(note,offset)
  if note_is_sharp(note) == true then notes = { 1,3,6,8,10 } else notes = { 0,2,4,5,7,9,11 } end
  octave = note_to_octave(note)
  from = index_of(notes,note % 12)
  new_note = notes[((from+offset) % #notes)]
  new_octave = ((octave+math.floor((from+offset)/#notes))*12)
  if new_note == nil then
    print('issue:',note,offset)
    return 0
  end
  return new_octave + new_note
end

function note_to_octave(number)
  return math.floor(number / 12)
end

function note_to_format(number)
  if number == nil then return 'MUTE' end
  note = note_to_name(number)
  octave = note_to_octave(number)
  return note..''..octave
end

function note_to_name(number)
  names = { 'C','C#','D','D#','E','F','F#','G','G#','A','A#','B' }
  return names[(number % 12)+1]
end

function note_is_sharp(note)
  notes = { false,true,false,true,false,false,true,false,true,false,true,false } 
  return notes[(note % 12)+1]
end

function index_of(list,value)
  for i=1,#list do
    if list[i] == value then return i end
  end
  return -1
end

function delta_format(value)
  if value > 0 then return '+'..value else return value end
end

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

-- Timer

re = metro.init()
re.time = 0.5
re.event = function()
  release_note()
  run()
  send_note()
  viewport.frame = viewport.frame + 1
end