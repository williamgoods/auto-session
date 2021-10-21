local self_session_library = {}

function self_session_library:exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

function self_session_library:get_current_time()
	math.randomseed(os.time())
	local random_suffix = math.random(1000, 1000000)
	local current_time = "/tmp/current_time" .. random_suffix

	os.execute("echo $(($(date +%s%N)/1000000)) > " .. current_time)
	local current_time_file = io.open(current_time,"r")
	local time = tonumber(current_time_file:read())

	current_time_file:close()
	os.execute("rm " .. current_time)

	return time
end

function self_session_library:FileOpration(filename, operation, filefunc)
	local file = io.open(filename, operation)
	filefunc(file)
	file:close()
end

return self_session_library
