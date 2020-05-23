local BeatClock = require "beatclock"
local MusicUtil = require "musicutil"

engine.name = 'PolyPerc'

g = grid.connect()
-- GLOBAL VALUES
BEATS = 4
ON = 15
--print(ON)

local midi_out_channel
local midi_out_device

local function table_sum(t)
  local y = 0
  for x = 1, #t do
    y = y + t[x]
  end
  return y
end

local function binary_value(t)
  local y = 0
  for x = 1, #t do
    if t[x] == 1 then
      y = y + bit32.lshift(1, x - 1)
    end
  end
  return y
end

-- https://rosettacode.org/wiki/Matrix_transposition#Lua
local function transpose(m)
  local res = {}
    for i = 1, #m[1] do
        res[i] = {}
        for j = 1, #m do
            res[i][j] = m[j][i]
        end
    end
    return res
end

g.key = function(x,y,z)
  print(x,y,z)
  if z == 1 then
    if x <= 4 and y >=2 and y < 6 then
      values[x][6 - y] = 1 - values[x][6 - y]
      --values[x] = bit32.bxor(values[x], bit32.lshift(1, 6 - y))
      --print(table_sum(values[x]))
    end
  end
end

local function draw_values(s)
  for x = 1, 4 do
    for y = 1, 4 do
      if values[x][y] == 1 then
        g:led(x, 6-y, ON)
      end
    end
  end
end

local function play(n)
  --local freq = n * 110
  --engine.hz(freq)
  --local note = MusicUtil.freq_to_note_num(freq)
  local scale = MusicUtil.generate_scale_of_length(48, "Dorian", 15)
  local note = scale[n]
  --print(n, last_note, note)
  print(note)
  midi_out_device:note_off(last_note, 69, midi_out_channel)
  midi_out_device:note_on(note, 64, midi_out_channel)
  last_note = note
end

local function advance_step()
  g:all(0)

  beat = ((beat + 1) % BEATS)
  if beat == 0 then
    seq = 1 - seq
  end
  
  draw_values(seq)
  if seq == 1 then
    g:led(beat + 1, 1, ON)
  else
    g:led(BEATS + 1, BEATS - beat + 1, ON)
  end
  
  --print("the value is " .. binary_value(values[beat + 1]), binary_value(transpose(values)[beat + 1]))
  if seq == 1 and binary_value(values[beat + 1]) > 0 then
    play(binary_value(values[beat + 1]))
  end
  if seq == 0 and binary_value(transpose(values)[beat + 1]) > 0 then
    play(binary_value(transpose(values)[beat + 1]))
  end
  g:refresh()
end

local function do_stop()
end


function init()

  seq = 0
  values = {
    {0,0,0,0},
    {0,0,0,0},
    {0,0,0,0},
    {0,0,0,0}
  }
  beat = 0
  beat_clock = BeatClock.new()
  
  midi_out_device = midi.connect(1)
  midi_out_device.event = function() end

  beat_clock.on_step = advance_step
  beat_clock.on_stop = do_stop
  beat_clock:start()
  
  params:add{type = "number", id = "midi_out_channel", name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      midi_out_channel = value
    end}
end
