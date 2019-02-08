describe("unit test -", function()
  
    -- import functions from abs.lua and search.lua files
    local abs = require('abs')
    local search = require('search')

    -- define ngx object 
    ngx = {
        say = function(s) print(s) end,
        print = function(s) print(s) end,
        var = {
            request_uri = "/abs/2018EPJWC.18608001A/abstract",
            QUERY_STRING = "?whoknows=True",
            scheme = "http",
            host = "ui.adsabs.harvard.edu"
        },
        header = {
            content_type = "html"
        },
        redirect = function(s) end,
        location = {
            capture = function(s) return { header = {}, status = 200, body = "<html></html>"} end
        },
        exit = function(s) end
    }
    
    -- mock ngx object using busted function
    -- store in global var
    _G.ngx = mock(ngx, false)
    
    -- define pgmoon object 
    pg = {
        connect = function(self) return true, nil end,
        query = function(self, s) return { { content = 'from mocked db!'  } } end,
        escape_literal = function(self, s) return s end,
        keepalive = function(self) end
    }

    -- mock pgmoon object using busted function
    -- store in global var
    _G.pg = mock(pg, false)

    it('checks if bibcode is nil', function()
        local b = abs.getBibcode()
        assert.is_true(b ~= nil and b ~= "" and b ~= " ")
    end)

    it('checks that setting the bibcode from unit test works', function()
        -- store string bibcode var
        local bibcode = "2018EPJWC.18608001A"

        -- set ngx global var to string val
        ngx.var.request_uri = "/abs/" .. bibcode .. "/abstract"

        -- get bibcode using abs function
        local b = abs.getBibcode()

        -- check that they are the same
        assert.is_true(b == bibcode)
    end)

    it('checks that pgmoon connect to db function was called', function()
        -- store string bibcode var
        local bibcode = "2018EPJWC.18608001A"

        -- set ngx global var to string val
        ngx.var.request_uri = "/abs/" .. bibcode .. "/abstract"

        abs.run()

        assert.spy(_G.pg.connect).was.called()

        -- clear call history
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
    end)

    it('checks if bibcode is correct length', function()
        -- get bibcode 
        local b = abs.getBibcode()

        -- check length
        assert(string.len(b) == 19)
    end)

    it('checks the return value for url that is nil', function()
        -- set request equal to null
        ngx.var.request_uri = "/abs//abstract"

        -- call run function 
        abs.run()

        -- check display 
        assert.spy(_G.ngx.say).was.called_with("Invalid URI.")

        -- check that it exits
        assert.spy(_G.ngx.exit).was.called()

        -- check exit code 
        assert.spy(_G.ngx.exit).was.called_with(404)

        -- clear call history
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
    end)

    it('checks the return value for url with a bibcode that is too long', function()
        
        -- set request to a value with a bibcode that is too long
        ngx.var.request_uri = "/abs/2018EPJWC.18608001AB/abstract"

        -- call run function
        abs.run()

        -- checks display
        assert.spy(_G.ngx.say).was.called_with("Invalid URI.")

        -- check that it exits
        assert.spy(_G.ngx.exit).was.called()

        -- checks exit code
        assert.spy(_G.ngx.exit).was.called_with(404)

        -- clear call history
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
        _G.pg.query:clear()
    end)

    it('checks the return value for url with a 19 character bibcode', function()
        -- set request to a value with a bibcode that is too long
        ngx.var.request_uri = "/abs/2018EPJWC.18608001A/abstract"

        -- call run function
        abs.run()

        -- check that query and esacpe_literal functions called
        -- and result from db is displayed 
        assert.spy(_G.pg.query).was.called()
        assert.spy(_G.pg.escape_literal).was.called()
        assert.spy(_G.ngx.say).was.called_with('from mocked db!')

        -- clear call history
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
    end)

    it('checks the return value for db connection failure', function()
        local err = "Connection failure."

        -- define a local pg object that fails to connect 
        local pg_fail = {
            connect = function(self) return false, err end,
            query = function(self, s) return nil end,
            escape_literal = function(self, s) return s end
        }

        -- mock pgmoon object that fails to connect to db
        _G.pg = mock(pg_fail, false)

        -- run main function 
        abs.run()

        -- check that connect was called, correct error message displayed and 503 returned 
        assert.spy(_G.pg.connect).was.called()
        assert.spy(_G.ngx.say).was.called_with("Could not connect to the database.")
        assert.spy(_G.ngx.exit).was.called_with(503)

        -- clear ngx function call history
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
    end)

    it('checks the return value when target is not found in db', function()
        -- define a local pg object whose query function returns nil 
        local pg_notfound = {
            connect = function(self) return true, nil end,
            query = function(self, s) return nil end,
            escape_literal = function(self, s) return s end
        }

        -- mock pgmoon object that fails to connect to db
        _G.pg = mock(pg_notfound, false)

        -- run main function 
        abs.run()

        -- check that connect and query were called
        -- and location.capture was called with correct parameters 
        assert.spy(_G.pg.connect).was.called()
        assert.spy(_G.pg.query).was.called()
        assert.spy(_G.ngx.location.capture).was.called()
        assert.spy(_G.ngx.location.capture).was.called_with("/proxy_abs/" .. ngx.var.request_uri:sub(6) .. "?" .. ngx.var.QUERY_STRING)
     
        -- clear location.capture function call history
        _G.ngx.location.capture:clear()

        -- set parameters equal to null
        ngx.var.QUERY_STRING = nil

        -- run main function
        abs.run()

        -- check that location.capture was called with correct parameters
        assert.spy(_G.ngx.location.capture).was.called_with("/proxy_abs/" .. ngx.var.request_uri:sub(6))
    end)

    it('checks the search proxy redirect', function()
        -- set ngx global var to string val
        ngx.var.request_uri = "/search/q=star&sort=date%20desc%2C%20bibcode%20desc&p_=0"
        ngx.var.QUERY_STRING = nil
        ngx.location.capture = function(s) return { header = {}, status = 200, body = "<html></html>"} end
        spy.on(_G.ngx.location, 'capture')

        -- run main function 
        search.run()

        assert.spy(_G.ngx.location.capture).was.called()
        assert.spy(_G.ngx.location.capture).was.called_with("/proxy_search/" .. ngx.var.request_uri:sub(9))
     
        -- check that connect was called, correct error message displayed and 503 returned 
        assert.spy(_G.ngx.print).was.called_with("<html></html>")

        -- clear ngx function call history
        _G.ngx.location.capture:clear()
        _G.ngx.print:clear()

        ngx.location.capture = function(s) return nil end

        -- run main function 
        search.run()

        assert.spy(_G.ngx.location.capture).was.called()
        assert.spy(_G.ngx.location.capture).was.called_with("/proxy_search/" .. ngx.var.QUERY_STRING)
     
        -- check that connect was called, correct error message displayed and 503 returned 
        assert.spy(_G.ngx.say).was.called_with("Could not proxy to the service.")
        --
        -- check that it exits
        assert.spy(_G.ngx.exit).was.called()

        -- check exit code 
        assert.spy(_G.ngx.exit).was.called_with(503)

        -- clear ngx function call history
        _G.ngx.location.capture:clear()
        _G.ngx.say:clear()
        _G.ngx.exit:clear()
    end)

end)
