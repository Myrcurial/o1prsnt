-- o1harness.lua -- headless test harness library for Osborne 1 (MAME)
--
-- This file is a LIBRARY: it defines the global table H with helpers for
-- driving and observing an emulated Osborne 1. It is not run directly --
-- concatenate it with a test script (see run-test.sh):
--
--     cat o1harness.lua mytest.lua > /tmp/run.lua
--
-- or start your test file from template.lua, which inlines these helpers.
--
-- Requires MAME invoked roughly like:
--   SDL_VIDEODRIVER=dummy mame osborne1 -flop1 IMAGE.imd -video none \
--     -sound none -nothrottle -autoboot_script /tmp/run.lua \
--     -seconds_to_run N -rompath ROMS_DIR

local MAME = manager.machine

H = {}

-- ---------------------------------------------------------------------------
-- Hardware constants (from the MAME osborne1 driver memory map)
-- ---------------------------------------------------------------------------
H.VRAM_BASE  = 0xF000   -- bank-1 upper 4K holds the 8-bit half of video RAM
H.VRAM_STRIDE = 128     -- bytes per character row (32 rows total, 24 visible)
H.ACIA_STATUS = 10752   -- 0x2A00, serial ACIA status (DCD=bit2, CTS=bit3)
H.BEEPER_PORT = 11266   -- 0x2C02, video PIA port B; bit 5 drives the beeper

H.kb    = MAME.natkeyboard                              -- keyboard injector
H.space = MAME.devices[":maincpu"].spaces["program"]    -- CPU program space

-- ---------------------------------------------------------------------------
-- Screen observation
-- ---------------------------------------------------------------------------

-- Read the whole video RAM as 32 rows of text (non-printables become spaces).
-- NOTE: the hardware scroll register rotates which VRAM row is at the top, so
-- always search the full buffer for text rather than assuming absolute rows
-- after any scrolling output.
function H.screen_text()
  local t = {}
  for row = 0, 31 do
    local s = ""
    for col = 0, H.VRAM_STRIDE - 1 do
      local b = H.space:read_u8(H.VRAM_BASE + row * H.VRAM_STRIDE + col) % 128
      s = s .. ((b >= 32 and b < 127) and string.char(b) or " ")
    end
    t[#t + 1] = s
  end
  return table.concat(t, "\n")
end

-- Plain-text substring search over the current screen buffer.
function H.find(pat)
  return H.screen_text():find(pat, 1, true) ~= nil
end

-- Print all non-blank screen rows (tagged), trimmed. Your eyes on the machine.
function H.dump(tag, max_cols)
  max_cols = max_cols or 59
  print("=== DUMP " .. tostring(tag) .. " ===")
  for row = 0, 23 do
    local s = ""
    for col = 0, max_cols do
      local b = H.space:read_u8(H.VRAM_BASE + row * H.VRAM_STRIDE + col) % 128
      s = s .. ((b >= 32 and b < 127) and string.char(b) or " ")
    end
    s = s:gsub("%s+$", "")
    if #s > 0 then print(string.format("r%02d|%s", row, s)) end
  end
end

-- Poll until pat appears or timeout (emulated seconds). Prints progress.
function H.wait_for(pat, timeout)
  local t = 0
  while t < timeout do
    if H.find(pat) then print("FOUND: " .. pat) return true end
    emu.wait(0.5) t = t + 0.5
  end
  print("TIMEOUT: " .. pat)
  H.dump("at timeout")
  return false
end

-- ---------------------------------------------------------------------------
-- Keyboard input
-- ---------------------------------------------------------------------------

-- Post raw text to the keyboard (no CR appended).
-- WARNING: natkeyboard types at a fixed pace and DROPS characters if you post
-- again while it is still typing, and the guest may flush its input buffer
-- during disk I/O. H.type_line() paces conservatively; verify critical input
-- with H.wait_for() on its echo.
function H.send(text)
  H.kb:post(text)
end

-- Post text + carriage return, then wait long enough for it to be typed
-- (~0.15s per character plus margin). Use for CP/M and MBASIC command lines.
function H.type_line(text)
  H.kb:post(text .. "\r")
  emu.wait(#text * 0.15 + 1.5)
end

-- Count of "Ok" prompts currently on screen. MBASIC prints a fresh "Ok" after
-- every direct-mode command, but old ones linger and scroll off, so a plain
-- wait_for("Ok") can match a STALE prompt. Compare counts instead:
--   local n = H.ok_count(); H.type_line('load"X.BAS"'); H.wait_new_ok(n)
function H.ok_count()
  local _, n = H.screen_text():gsub("Ok", "")
  return n
end

function H.wait_new_ok(previous, timeout)
  local t = 0
  while t < (timeout or 60) do
    emu.wait(0.5) t = t + 0.5
    if H.ok_count() > previous then return true end
  end
  print("NO-OK (stuck?)"); H.dump("no-ok")
  return false
end

-- ---------------------------------------------------------------------------
-- High-level flows
-- ---------------------------------------------------------------------------

-- Cold boot CP/M: the BIOS sits at "Insert disk in Drive A and press RETURN."
-- until RETURN arrives, then boots to the A> prompt.
function H.boot_cpm()
  emu.wait(2)
  H.send("\r")
  return H.wait_for("A>", 30)
end

-- Run an MBASIC program from the A> prompt (e.g. H.run_mbasic("o1prsnt")).
-- The CCP uppercases the command tail for you, so case does not matter here
-- (unlike MBASIC's own LOAD command, which needs upper case!).
function H.run_mbasic(name)
  H.type_line("mbasic " .. name)
end

-- Emulated seconds since machine start -- handy for timing measurements.
function H.time()
  return emu.time()
end

-- Assertion helper: if ok is false/nil, print FAIL and exit non-zero.
function H.check(ok, msg)
  if not ok then
    print("FAIL: " .. tostring(msg))
    H.dump("at failure")
    H.finish(1)
  end
end

-- End the test run cleanly. (Letting MAME exit via -seconds_to_run instead
-- often ends in a segfault in the macOS headless teardown; os.exit avoids it.)
function H.finish(code)
  os.exit(code or 0)
end
