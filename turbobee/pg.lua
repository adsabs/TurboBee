local M = {}
local pgmoon = require("pgmoon")

function M.new()
    local pg = pgmoon.new({
        host = os.getenv("DATABASE_HOST"),
        port = os.getenv("DATABASE_PORT"),
        database = os.getenv("DATABASE_NAME"),
        user = os.getenv("DATABASE_USER"),
        password = os.getenv("DATABASE_PASSWORD")
    })
    return pg
end

return M
