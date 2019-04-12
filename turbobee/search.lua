local M = {}

function M.run(pg)
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
         ngx.status = res.status
         ngx.header = res.header
         ngx.print(res.body)
     else
        local err = "Could not proxy to the service."
        ngx.log(ngx.ERR, err)
        ngx.status = 503
        ngx.say(err)
    end
    return ngx.status
end

return M
