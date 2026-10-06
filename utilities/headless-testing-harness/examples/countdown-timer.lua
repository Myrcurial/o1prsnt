-- countdown-timer.lua -- example end-to-end test for the o1prsnt countdown
-- timer slide (the 'T MM:SS' content code). Run via run-test.sh:
--
--   ./run-test.sh examples/countdown-timer.lua ~/Documents/Osborne1/floppies/o1prsnt.imd 240
--
-- It boots CP/M, starts the presentation, walks to the timer slide of the
-- bundled example deck (examples/CONTENT.TXT on the floppy), then samples the
-- screen once per second, reporting which VRAM rows carry a M:SS value, and
-- finally waits for the auto-advance end screen.
--
-- NOTE: if the floppy still carries a program version without the countdown
-- display fix, expect the value to walk across rows; with the fix it stays on
-- one row.

H.check(H.boot_cpm(), "boot to CP/M")

H.run_mbasic("o1prsnt")
H.check(H.wait_for("Press any key", 90), "splash screen")
H.send("x")                       -- dismiss the splash screen

-- Walk to slide 5 (the example deck's timer slide). Each footer shows "n / 5".
for s = 2, 5 do
  H.check(H.wait_for((s - 1) .. " / 5", 20), "slide " .. (s - 1))
  H.send("N")
end
H.check(H.wait_for("COUNTDOWN TIMER TEST", 20), "timer slide")
print("timer slide reached at t=" .. H.time())

-- Sample rows containing a M:SS pattern for ~20 emulated seconds.
local function timer_rows()
  local out = {}
  for row = 0, 23 do
    local line = ""
    for col = 0, 51 do
      local b = H.space:read_u8(H.VRAM_BASE + row * H.VRAM_STRIDE + col) % 128
      line = line .. ((b >= 32 and b < 127) and string.char(b) or " ")
    end
    local _, _, val = line:find("(%d+:%d%d)")
    if val then out[#out + 1] = string.format("r%02d=%s", row, val) end
  end
  return table.concat(out, "  ")
end

for _ = 1, 20 do
  emu.wait(1)
  print(string.format("t=%.1f  %s", H.time(), timer_rows()))
end

-- Slide 5 is the last slide: at 0:00 the program beeps, dwells, and
-- auto-advances into the end-of-deck screen.
if H.wait_for("Presentation Complete", 120) then
  print("PASS: countdown beep + auto-advance observed at t=" .. H.time())
  H.finish(0)
else
  print("FAIL: no auto-advance")
  H.finish(1)
end
