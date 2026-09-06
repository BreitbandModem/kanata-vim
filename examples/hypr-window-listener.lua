local last_vim_direct_action = nil

local function send_fake_key(port, key_name, action)
  local payload = string.format(
    '{"ActOnFakeKey":{"name":"%s","action":"%s"}}',
    key_name,
    action
  )

  local cmd = string.format(
    "printf '%%s\\n' %s | socat -u - TCP:localhost:%d,connect-timeout=1 >/dev/null 2>&1",
    o.shell_quote(payload),
    port
  )

  if not o.shell_succeeds(cmd) then
    print("window-listener: kanata port " .. tostring(port) .. " unreachable")
  end
end

local function toggle_context(action)
  send_fake_key(10000, "vim-direct-enter", action)
end

local function window_is_terminal(window)
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function desired_action_for(window)
  if window_is_terminal(window) then
    return "Release"
  end
  return "Press"
end

local function apply(window)
  local action = desired_action_for(window)
  if action == last_vim_direct_action then
    return
  end
  toggle_context(action)
  last_vim_direct_action = action
end

hl.on("window.active", apply)

-- initialize once at startup
hl.on("hyprland.start", function()
  apply(hl.get_active_window())
end)
