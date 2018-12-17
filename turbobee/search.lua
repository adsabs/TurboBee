local M = {}

function M.run()
    local destination = ngx.var.request_uri:sub(9) -- Ignore '/search/'
    local parameters = ngx.var.QUERY_STRING
    if parameters then
        ngx.redirect("/#search/" .. destination .. "/" .. parameters)
    else
        ngx.redirect("/#search/" .. destination)
    end
end


-- a simple test
function M.add(v1, v2)
  return v1 + v2
end

return M
