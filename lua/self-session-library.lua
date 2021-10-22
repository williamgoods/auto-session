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

function self_session_library:RestoreSpeed(interval)
		local speed_config = ""
		local speed_dir = vim.env.HOME .. "/.vim/neovim_speed" .. vim.fn.getcwd()
		local speed_file = speed_dir .. "/speed"

		self:FileOpration(speed_file, "r", function (filehandler)
			speed_config = filehandler:read()
		end)

		local speed_json = vim.fn.json_decode(speed_config)

		local previous_buffers_size = speed_json["buffers_size"]
		local current_speed = interval / previous_buffers_size

		speed_json["previous_speed"] = current_speed

		self:FileOpration(speed_file, "w", function (filehandler)
			filehandler:write(vim.fn.json_encode(speed_json))
		end)
end

function self_session_library:SaveSpeed()
	local speed_dir = vim.env.HOME .. "/.vim/neovim_speed" .. vim.fn.getcwd()
	local dir_ok, _ = self:exists(speed_dir)
	-- print(speed_dir)
	if not dir_ok then
		os.execute("mkdir -p " .. speed_dir)
	end

	local speed_file = speed_dir .. "/speed"
	local file_ok, _ = self:exists(speed_file)

	if not file_ok then
		os.execute("touch " .. speed_file)
	end

	local buffers_size = 0
	local all_buffers = vim.api.nvim_list_bufs()
	for _, value in ipairs(all_buffers) do
		-- print("key: " .. key .. ", value: " .. value .. "\n")
		-- print("lines: " .. tostring(vim.api.nvim_buf_line_count(value)) .. "\n")
		buffers_size = buffers_size + vim.api.nvim_buf_line_count(value)
	end

	local buffers_size_k = (buffers_size - buffers_size % 1000) / 1000 + 1
	-- print("buffers_size: " .. buffers_size_k .. "k")

	--{
	--  first = 1(default: 1, after first load, this will be 0),
	--  previous_speed = number(default: 500ms),
	--  buffers_size = size,
	--}

	local speed_config = ""

	self:FileOpration(speed_file, "r", function (filehandler)
		speed_config = filehandler:read()
	end)

	if not speed_config then
		local speed = {
			first = 1,
			previous_speed = 500,
			buffers_size = 1,
		}

		local speed_json = vim.fn.json_encode(speed)

		self:FileOpration(speed_file, "w", function (filehandler)
			filehandler:write(speed_json)
		end)
	else
		local speed_decode = vim.fn.json_decode(speed_config)

		speed_decode['buffers_size'] = buffers_size_k

		local re_speed_config = vim.fn.json_encode(speed_decode)

		self:FileOpration(speed_file, "w", function (filehandler)
			filehandler:write(re_speed_config)
		end)
	end
end

local function FileOpration(filename, operation, filefunc)
	local file = io.open(filename, operation)
	filefunc(file)
	file:close()
end

local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

local function DelayStart()
	local default_speed = {
		first = 1,
		previous_speed = 500,
		buffers_size = 1,
	}

	local speed_dir = vim.env.HOME .. "/.vim/neovim_speed" .. vim.fn.getcwd()
	local speed_file = speed_dir .. "/speed"

	local file_ok, _ = exists(speed_file)
	local speed  = default_speed.buffers_size * default_speed.previous_speed

	if file_ok then
		local speed_json = ""

		FileOpration(speed_file, "r", function (filehandler)
			speed_json = filehandler:read()
		end)

		local current_speed = vim.fn.json_decode(speed_json)

		speed = current_speed.buffers_size * current_speed.previous_speed
	end

	return speed
end

return self_session_library
