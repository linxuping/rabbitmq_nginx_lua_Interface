local rabbitmq = require "rabbitmqstomp"
local config = require "config"
local errf = assert(io.open(config.error_log, "a"))

ngx.header.content_type = "text/html";
ngx.status = ngx.HTTP_OK
args = ngx.req.get_post_args()
queue = args["queue"]
data = args["data"]

local opts = {username = config.username, password = config.password, vhost = config.vhost}

local mq, err = rabbitmq:new(opts)
if not mq then
    ngx.say(0)
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

mq:set_timeout(config.timeout)

local ok, err = mq:connect(config.host, config.port)
if not ok then
    ngx.say(0)
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

local headers = {}
headers["destination"] = "/queue/"..queue
headers["persistent"] = "true"

local ok, err = mq:send(data, headers)
if not ok then
    ngx.say(0)
    errf:write(err.."\n")
    errf:close()
    mq:close()
    return
end

ngx.say(1)
errf:close()
mq:close()
