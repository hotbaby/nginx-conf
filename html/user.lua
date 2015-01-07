#! /usr/bin/env lua

--[[

USER MANAGER MODULE

--]]

package.path    = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath   = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local os        = require('os')
local sqlite3   = require('lsqlite3')
local safesql   = require('safesql')

module('user', package.seeall)

local expire     = 86400
local session_db = '/usr/lib/service-manager/usrmgn/session.db'

function check(...)
    args = { ... }
    local token

    token = args[1]
    if type(token) ~= 'string' then
        return false
    end

    local db
    local sql
    local found

    sql = 'select * from session where token=' .. '\'' .. token .. '\''

    db = sqlite3.open(session_db)
    if db ~= nil then

        local ret, rows = {}
        ret, rows = safesql.safeExeSqliteSelect(db, sql)
        if ret == 0 and #rows > 0 then

            local create_time, current_time

            create_time = rows[1]['ctime']
            current_time = os.time()
            if current_time - create_time < expire then
                found = true
            else
                found = false
            end
        else
            found = false
        end

        db:close()
    else
        return false
    end

    if found == true then
        return true
    else
        return false
    end
end
