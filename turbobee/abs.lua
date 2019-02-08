local M = {}

function M.getBibcode()
    local destination = ngx.var.request_uri

    if destination == nil then 
        return nil
    else
        local destination = destination:sub(6) -- Ignore '/abs/'
        local size = destination:len()  

        for i = 1, destination:len(), 1
        do
            if destination:sub(i,i) == '/' then
                size = i-1
                break 
            end
        end

        return destination:sub(1, size) -- split at first '/', return full string if none are found  
    end
end 

function M.run()

    success, err = pg:connect()

    if success then
        local destination = ngx.var.request_uri:sub(6) -- Ignore '/abs/'
        local bibcode = M.getBibcode()

        if bibcode == nil or bibcode:len() ~= 19 then
            ngx.status=404 -- Bibcode should be 19 characters
            ngx.say("Invalid URI.")
            ngx.exit(404)
        else 
            local target = ngx.var.scheme .. "://" .. ngx.var.host .. "/abs/" .. bibcode .. "/abstract" -- https://dev.adsabs.harvard.edu/abs/<bibcode>/abstract
            local result = pg:query("SELECT content FROM pages WHERE target = " .. pg:escape_literal(target))

            if result and result[1] and result[1]['content'] then
                ngx.header.content_type = result[1]['content_type']
                ngx.say(result[1]['content'])
            else
                local parameters = ngx.var.QUERY_STRING
                local url = ""
                if parameters then
                    url = "/proxy_abs/" .. destination .. "?" .. parameters
                else
                    url = "/proxy_abs/" .. destination
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
        end
    else
        ngx.status = 503
        ngx.say("Could not connect to the database.")
        return ngx.exit(503)
    end

end

return M
