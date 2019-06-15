-- scriptname: Monitor
-- v1.0.0 @neauoire
-- llllllll.co/t/norns-tutorial/23241

local midi_signal
local viewport = { width = 128, height = 64, frame = 0 }
local mods = { transpose = 0, channel = 0 }


-- Main

function init()
  connect()
  -- Render Style
  screen.level(20)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  redraw()
end

function connect()
  midi_signal = midi.connect()
  midi_signal.event = on_midi_event
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  redraw(msg)
end

-- Interactions

function key(id,state)
  if state == 1 and midi_signal then
    midi_signal.note_on(60,127)
  elseif midi_signal then
    midi_signal.note_off(60,127)
  end
  redraw()
end

function enc(id,delta)
  redraw()
end

-- Render

function draw_octave(msg)
  offset = { x = 5, y = 24 }
  template = { w = 10, h = 36, sw = 4, sh = 15 }
  
  screen.level(20)
  
  if msg and msg.type == 'note_on' then
    if msg.note % 12 == 0 then screen.rect(offset.x, offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 2 then screen.rect(offset.x + (template.w*1), offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 4 then screen.rect(offset.x + (template.w*2), offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 5 then screen.rect(offset.x + (template.w*3), offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 7 then screen.rect(offset.x + (template.w*4), offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 9 then screen.rect(offset.x + (template.w*5), offset.y, template.w, template.h) ; screen.fill() end
    if msg.note % 12 == 11 then screen.rect(offset.x + (template.w*6), offset.y, template.w, template.h) ; screen.fill() end
  end
  
  -- White
  screen.rect(offset.x, offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*1), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*2), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*3), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*4), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*5), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*6), offset.y, template.w, template.h)
  screen.stroke()
  
  -- Black
  screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh)
  screen.level(0)
  screen.fill()
  
  screen.level(20)
  
  if msg and msg.type == 'note_on' then
    if msg.note % 12 == 1 then screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
    if msg.note % 12 == 3 then screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
    if msg.note % 12 == 6 then screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
    if msg.note % 12 == 8 then screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh) ;  screen.fill() end
    if msg.note % 12 == 10 then screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
  end
  
  -- Black Outline
  screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh)
  screen.stroke()
end

function draw_labels(msg)
  if msg and msg.note then
    -- screen.move(75,18)
    -- screen.text_right(msg.note)
    screen.move(5,18)
    screen.text(note_to_name(msg.note)..math.floor(msg.note/12)..' '..msg.note)
    screen.move(5,10)
    screen.text('ch'..msg.ch)
  end
end

function redraw(msg)
  screen.clear()
  draw_labels(msg)
  draw_octave(msg)
  screen.stroke()
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
