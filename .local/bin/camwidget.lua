-- camwidget.lua — tappable Capture / Copy / Fullscreen controls for the camera
-- peek widgets. Loaded via mpv --script=. Touch taps arrive as MBTN_LEFT
-- (--input-touch-emulate-mouse=yes). Icons are background-less glyphs (outline +
-- shadow for legibility on video); their hit boxes are a bit larger for fingers.
-- Capture/Copy use mpv's screenshot of the *video* (so the buttons aren't in the
-- shot, and any rotation vf is baked in). Capture -> Documents/Photos/...,
-- Copy -> wl-copy, Fullscreen -> cam-fullscreen helper.

local overlay = mp.create_osd_overlay("ass-events")
local buttons = {}
local CHARTREUSE = "78FFFF"   -- ASS colour is BGR, so #ffff78 -> 78 FF FF

local function redraw()
    local dim = mp.get_property_native("osd-dimensions")
    if not dim or not dim.w or dim.w == 0 then return end
    local W, H = dim.w, dim.h
    overlay.res_x, overlay.res_y = W, H

    local bh = math.max(30, math.min(80, math.floor(H * 0.22)))
    local bw = bh
    local m = math.max(8, math.floor(bh * 0.30))
    local y = H - m - bh

    -- left-to-right along the bottom-right corner
    local defs = {
        { action = "capture",    glyph = "󰄀" },
        { action = "copy",       glyph = "󰆏" },
        { action = "fullscreen", glyph = "󰊓" },
    }
    buttons = {}
    local n = #defs
    for i, d in ipairs(defs) do
        local from_right = n - i                  -- last button -> 0
        local x = W - m - bw - from_right * (bw + m)
        buttons[#buttons + 1] = { x = x, y = y, w = bw, h = bh, action = d.action, glyph = d.glyph }
    end

    local p = {}
    for _, b in ipairs(buttons) do
        local fs = math.floor(b.h * 0.74)
        -- no background box: chartreuse glyph with a black outline + drop shadow
        p[#p + 1] = string.format(
            "{\\an5\\pos(%d,%d)\\fnSymbols Nerd Font Mono\\fs%d\\1c&H%s&\\bord3\\3c&H000000&\\shad2\\4c&H000000&}%s",
            b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2), fs, CHARTREUSE, b.glyph)
    end
    overlay.data = table.concat(p, "\n")
    overlay:update()
end

local function toast(glyph_text)
    mp.commandv("run", "notify-send", "-t", "1200",
        "-h", "string:x-dunst-stack-tag:camphoto", glyph_text)
end

local function on_click()
    local pos = mp.get_property_native("mouse-pos")
    if not pos then return end
    for _, b in ipairs(buttons) do
        if pos.x >= b.x and pos.x <= b.x + b.w and pos.y >= b.y and pos.y <= b.y + b.h then
            if b.action == "capture" then
                mp.commandv("screenshot", "video")
                toast("󰄀  Photo saved")
            elseif b.action == "copy" then
                local clip = "/tmp/cam-clip.png"
                mp.commandv("screenshot-to-file", clip, "video")
                mp.commandv("run", os.getenv("HOME") .. "/.local/bin/cam-clip", clip)
            else
                local title = mp.get_property("title") or ""
                mp.commandv("run", os.getenv("HOME") .. "/.local/bin/cam-fullscreen", title)
            end
            return
        end
    end
end

mp.add_forced_key_binding("MBTN_LEFT", "camwidget-click", on_click)
mp.observe_property("osd-dimensions", "native", redraw)
mp.register_event("file-loaded", redraw)
