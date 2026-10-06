-- template.lua -- copy this to start a new headless test.
-- Run with: ./run-test.sh yourtest.lua [image.imd] [seconds]
--
-- The harness library is prepended by run-test.sh, so all H.* helpers are
-- available here directly. Remember:
--   - never type into disk I/O; wait_for() the expected banner first
--   - keys are single posts: H.send("N"); command lines: H.type_line("dir")
--   - assert on screen content, not on time passing

H.check(H.boot_cpm(), "boot to CP/M")

-- Example: list the directory and check a file is present
H.type_line("xdir")
if H.wait_for("O1PRSNT .BAS", 30) then
  print("PASS: program file present on disk")
  H.finish(0)
else
  print("FAIL: program file missing")
  H.finish(1)
end
