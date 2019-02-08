local M = {}

function M.run()
    local destination = ngx.var.request_uri:sub(9) -- Ignore '/search/'
    local parameters = ngx.var.QUERY_STRING
    local url = ""
    if parameters then
        url = "/proxy_search/" .. destination .. "?" .. parameters
    else
        url = "/proxy_search/" .. destination
    end
    local res = ngx.location.capture(url)
    if res then
         ngx.header = res.header
         ngx.status = res.status
         ngx.print(res.body)
     else
        ngx.status = 503
        ngx.say("Could not proxy to the service.")
        return ngx.exit(503)
    end
end

return M
