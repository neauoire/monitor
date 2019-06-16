-- scriptname: Monitor
-- v1.0.0 @neauoire
-- llllllll.co/t/monitor/23273

local midi_signal_in
local midi_signal_out
local viewport = { width = 128, height = 64, frame = 0 }
local mods = { transpose = 0, ch = 0 }
local keys_down = {}

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
  midi_signal_in = midi.connect(1)
  midi_signal_in.event = on_midi_event
  midi_signal_out = midi.connect(2)
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  traverse(msg)
  redraw(msg)
end

function traverse(msg)
  if msg and msg.type == 'note_on' then
    midi_signal_out:note_on(msg.note+mods.transpose,msg.vel,mods.ch+1)
    keys_down[msg.note % 12] = true
  else
    midi_signal_out:note_off(msg.note+mods.transpose,msg.vel,mods.ch+1)
    keys_down[msg.note % 12] = false
  end
end

-- Interactions

function key(id,state)
  mods.ch = 0
  mods.transpose = 0
  redraw()
end

function enc(id,delta)
  if id == 2 then
    mods.ch = clamp(mods.ch + delta,0,15)
  elseif id == 3 then
    mods.transpose = clamp(mods.transpose + delta,-24,24)
  end
  redraw()
end

-- Render

function draw_octave()
  offset = { x = 5, y = 24 }
  template = { w = 10, h = 36, sw = 4, sh = 15 }
  -- White Keys Down
  screen.level(20)
  if keys_down[0] then screen.rect(offset.x, offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[2] then screen.rect(offset.x + (template.w*1), offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[4] then screen.rect(offset.x + (template.w*2), offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[5] then screen.rect(offset.x + (template.w*3), offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[7] then screen.rect(offset.x + (template.w*4), offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[9] then screen.rect(offset.x + (template.w*5), offset.y, template.w, template.h) ; screen.fill() end
  if keys_down[11] then screen.rect(offset.x + (template.w*6), offset.y, template.w, template.h) ; screen.fill() end
  -- White Keys Outline
  screen.rect(offset.x, offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*1), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*2), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*3), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*4), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*5), offset.y, template.w, template.h)
  screen.rect(offset.x + (template.w*6), offset.y, template.w, template.h)
  screen.stroke()
  -- Black Keys Mask
  screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh)
  screen.level(0)
  screen.fill()
  -- Black Keys Down
  screen.level(20)
  if keys_down[1] then screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
  if keys_down[3] then screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
  if keys_down[6] then screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
  if keys_down[8] then screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh) ;  screen.fill() end
  if keys_down[10] then screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh) ; screen.fill() end
  -- Black Keys Outline
  screen.rect(offset.x + 7, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 17, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 37, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 47, offset.y, template.w - template.sw, template.h - template.sh)
  screen.rect(offset.x + 57, offset.y, template.w - template.sw, template.h - template.sh)
  screen.stroke()
end

function draw_labels(msg)
  screen.move(75,10)
  screen.text_right('> ch'..(mods.ch + 1))
  if msg and msg.note then
    screen.move(5,10)
    screen.text('ch'..msg.ch)
    screen.move(5,18)
    screen.text(note_to_name(msg.note)..math.floor(msg.note/12)..' '..msg.note)
    screen.move(75,18)
    screen.text_right(note_to_name(msg.note+mods.transpose)..math.floor((msg.note+mods.transpose)/12)..' '..(msg.note+mods.transpose))
  else
    screen.move(75,18)
    screen.text_right(mods.transpose)
  end
end

function redraw(msg)
  screen.clear()
  draw_labels(msg)
  draw_octave()
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
