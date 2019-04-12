local M = {}

local function split (input, s)
    local t = {}
    local i = 0
    for v in string.gmatch(input, '[^' .. s .. ']+') do
        i = i + 1
        t[i] = v
    end
    -- remove 'abstract' as it receives special treatment
    if i == 2 and t[2] == 'abstract' then
        t[2] = nil
        i = i - 1
    end

    return i, t
end

local function proxy_abs (destination, parameters)
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
        local err = "Could not proxy to the service."
        ngx.log(ngx.ERR, err)
        ngx.status = 503
        ngx.say(err)
    end

    return ngx.status
end


function M.run(pg)

    local destination = ngx.var.request_uri:sub(6) -- Ignore '/abs/'
    local parameters = ngx.var.QUERY_STRING

    _, success, err = pcall(pg['connect'], pg)

    if success == true then
        local i, parts = split(destination, '/')
        local bibcode = ngx.unescape_uri(parts[1])

        if bibcode == nil or i < 1 then
            ngx.status = 404
            ngx.say("Invalid URI.")
        else
            local target = "//" .. ngx.var.host .. "/abs/" -- //dev.adsabs.harvard.edu/abs/
            local result = nil

            if i > 1 then
                result = pg:query("SELECT content, content_type FROM pages WHERE target = " .. pg:escape_literal(target .. table.concat(parts, "/")) .. " ORDER BY updated DESC NULLS LAST")
            else
                result = pg:query("SELECT content, content_type FROM pages WHERE target = " .. pg:escape_literal(target .. bibcode ) .. " OR target = " .. pg:escape_literal(target .. bibcode .. "/abstract") .. " ORDER BY updated DESC NULLS LAST")
            end

            if result and result[1] and result[1]['content'] then
                ngx.status = 200
                ngx.header.content_type = result[1]['content_type']
                ngx.say(result[1]['content'])
            else
                if not result or result and result[1] == nil then
                    -- add an empty record (marker for pipeline to process this URL)
                    if i > 1 then
                        pg:query("INSERT into pages (qid, target) values (md5(random()::text || clock_timestamp()::text)::cstring, " .. pg:escape_literal(target .. table.concat(parts, "/")) .. ")")
                    else
                        pg:query("INSERT into pages (qid, target) values (md5(random()::text || clock_timestamp()::text)::cstring, " .. pg:escape_literal(target .. bibcode) .. ")")
                    end
                end

                ngx.status = proxy_abs(destination, parameters)
            end
        end
    else
        -- logging for db connection failure and errors
        err = err or success
        ngx.log(ngx.ERR, err)

        ngx.status = proxy_abs(destination, parameters)
    end

    return ngx.status
end

return M
