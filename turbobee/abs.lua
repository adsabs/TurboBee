local M = {}

local function split (input, s)
    local t = {}
    local i = 1
    for v in string.gmatch(input, '[^' .. s .. ']+') do
        t[i] = v
        t['#len'] = i
        i = i + 1
    end
    -- remove 'abstract' as it receives special treatment
    if t['#len'] == 2 and t[2] == 'abstract' then
        t[2] = nil
        t['#len'] = t['#len'] - 1
    end

    return t
end


function M.run()

    success, err = pg:connect()

    if success then
        local destination = ngx.var.request_uri:sub(6) -- Ignore '/abs/'
        local parts = split(destination, '/')
        local bibcode = parts[1]
        

        if bibcode == nil or bibcode:len() ~= 19 then
            ngx.status=404 -- Bibcode should be 19 characters
            ngx.say("Invalid URI.")
            ngx.exit(404)
        else 
            local target = "//" .. ngx.var.host .. "/abs/" .. bibcode -- //dev.adsabs.harvard.edu/abs/<bibcode>
            local result = nil

            if parts['#len'] > 1 then
                result = pg:query("SELECT content, content_type FROM pages WHERE target = " .. pg:escape_literal(target .. "/" .. parts[2]) .. " ORDER BY updated DESC NULLS LAST")
            else
                result = pg:query("SELECT content, content_type FROM pages WHERE target = " .. pg:escape_literal(target) .. " OR target = " .. pg:escape_literal(target .. "/abstract") .. " ORDER BY updated DESC NULLS LAST")
            end

            if result and result[1] and result[1]['content'] then
                ngx.header.content_type = result[1]['content_type']
                ngx.say(result[1]['content'])
            else
                if not result or result and result[1] == nil then
                    -- add an empty record (marker for pipeline to process this URL)
                    if parts['#len'] > 1 then
                        pg:query("INSERT into pages (qid, target) values (md5(random()::text || clock_timestamp()::text)::cstring, " .. pg:escape_literal(target .. "/" .. parts[2]) .. ")")
                    else
                        pg:query("INSERT into pages (qid, target) values (md5(random()::text || clock_timestamp()::text)::cstring, " .. pg:escape_literal(target) .. ")")
                    end
                end
                
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
