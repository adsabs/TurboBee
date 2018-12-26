local M = {}

function M.run()
    local pgmoon = require("pgmoon")
    local pg = pgmoon.new({
      host = os.getenv("DATABASE_HOST"),
      port = os.getenv("DATABASE_PORT"),
      database = os.getenv("DATABASE_NAME"),
      user = os.getenv("DATABASE_USER"),
      password = os.getenv("DATABASE_PASSWORD")
    })

    success, err = pg:connect()

    if success then
        -- get full url
        local url = ngx.var.host + ngx.var.uri
        local destination = ngx.var.request_uri:sub(6) -- Ignore '/abs/'

        -- extract bibcode from url
        -- local bibcode = destination:sub(1, 19) -- Use only 19 characters

        local result = pg:query("SELECT content,content_type FROM pages WHERE target = " ..  pg:escape_literal(url))

	-- set header to return content type from db 
	ngx.header.content_type = result[1]['content_type']

        if result and result[1] and result[1]['content'] then
            ngx.say(result[1]['content'])
        else
            -- ngx.status = 404
            -- ngx.say("Record not found.")
            -- return ngx.exit(404)
            local parameters = ngx.var.QUERY_STRING
            if parameters then
                ngx.redirect("/#abs/" .. destination .. "?" .. parameters)
            else
                ngx.redirect("/#abs/" .. destination)
          end
        end
    else
        ngx.say("Could not connect to db: " .. err)
        return ngx.exit(503)
    end

    -- Return connection to pool
    pg:keepalive()
    pg = nil
end

-- a simple test
function M.add(v1, v2)
  return v1 + v2
end

-- test database connection
function M.connect_to_db(temp_pg)
  success, err = temp_pg:connect()

  return success 
end

--
function M.alterDB(table, target, columnName, value)
  -- create local database?
  -- pg_test

  pg_test:("INSERT " .. value .. " INTO " columnName .. " WHERE target = " .. target)  
end

function M.
end

function M.
end

function M.
end

function M.
end

function M.
end

function M.
end

return M
