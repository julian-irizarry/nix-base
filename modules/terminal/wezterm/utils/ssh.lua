local M = {}

-- Helper to get SSH hostname from pane (using tabline's pane structure)
function M.get_ssh_host(pane)
	-- tabline passes a table with properties, not methods
	local process_name = pane.foreground_process_name or ""
	-- Check if the process is ssh
	if not process_name:match("ssh$") then
		return nil
	end

	-- Try to extract hostname from the pane title
	-- SSH often sets the terminal title to user@host or similar
	local title = pane.title or ""

	-- Try common patterns in SSH titles
	-- Pattern: user@hostname
	local host = title:match("@([%w%-%._]+)")
	if host then
		return host
	end

	-- Pattern: hostname (just the host if title is set)
	-- Check if title looks like a hostname (not a local path)
	if title ~= "" and not title:match("^/") and not title:match("^~") then
		-- Could be hostname or "user@host: path" format
		local potential_host = title:match("^([%w%-%._]+)")
		if potential_host and potential_host ~= process_name then
			return potential_host
		end
	end

	return "ssh"
end

return M
