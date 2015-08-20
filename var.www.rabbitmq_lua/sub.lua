local rabbitmq = require "rabbitmqstomp"
local config = require "config"
local errf = assert(io.open(config.error_log, "a"))

ngx.header.content_type = "text/html";
ngx.status = ngx.HTTP_OK
queue = ngx.var.arg_queue

local opts = {username = config.username, password = config.password, vhost = config.vhost}

local mq, err = rabbitmq:new(opts)
if not mq then
    ngx.say("")
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

mq:set_timeout(config.timeout)

local ok, err = mq:connect(config.host, config.port)
if not ok then
    ngx.say("")
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

local headers = {}
headers["destination"] = "/queue/"..queue
headers["persistent"] = "true"
headers["id"] = "1"
headers["ack"] = "client-individual"

local ok, err = mq:subscribe(headers)
if not ok then
    ngx.say("")
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

local data, err = mq:_receive_frame()
if not data then
    ngx.say("")
    errf:write(err.."\n")
    errf:close()
    mq:close()
	return
end

local idx = string.find(data, "\n\n", 1)
local msg = string.sub(data, idx + 2, data:len()-4)
local ack = string.match(data, "ack.-%s")
ack = string.sub(ack, 5)

headers = {}
headers["id"] = ack
local ok, err = mq:ack(headers)
if not ok then
    ngx.say("")
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

headers = {}
headers["persistent"] = "true"
headers["id"] = "1"

local ok, err = mq:unsubscribe(headers)
if not ok then
	errf:write(err.."\n")
end

ngx.say(msg)
errf:close()
mq:close()
