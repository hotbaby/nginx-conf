#! /usr/bin/env lua

--[[

USER MANAGER MODULE

--]]

package.path    = '/usr/lib/lua/?.lua;./html/?.lua;./?.lua;'
package.cpath   = '/usr/lib/lua/?.so;./html/?.so;./?.so;'

local os        = require('os')
local uuid      = require('uuid')
local sqlite3   = require('lsqlite3')

module('user', package.seeall)

local expire     =  2592000     --1 month
local session_db = '/home/homecloud/www/html/session.db'

function create()
end

function login(...)
    args = { ... }
    local token
    local username, password

    username = args[1]
    password = args[2]

    if username == nil or type(username) ~= 'string'
        or password == nil or type(password) ~= 'string' then
        return nil
    end

    local db
    local found = false
    local sql = 'select * from user where username=' .. '\'' .. username .. '\'' .. ' and ' .. 'password=' .. '\'' .. password .. '\''
    print(sql)

    db = sqlite3.open(session_db)
    if db ~= nil then

        local vm
        vm = db:prepare(sql)
        if vm:step() == sqlite3.ROW then
            found = true
        else
            found = false
        end
        vm:finalize()
        db:close()
    else
        return nil
    end

    if found == true then
        local ctime

        token = uuid.new('time')
        token = string.gsub(token, '-', '')
        ctime = os.time()

        db = sqlite3.open(session_db)
        if db ~= nil then
            sql = 'insert into session (token, username, ctime) values('..'\''..token..'\''..', '..'\'' .. username..'\''..', '..ctime..')'
    	    print(sql)
	    local ret = db:exec(sql) 
            print(ret)
            if ret ~= sqlite3.OK then
                print('user insert into session error: .', ret)
            else
                print('user insert into session ok. ')
            end
            db:close()
        else
            return nil
        end
    else
        return nil
    end

    return token
end

function passwd()
end

function userlist()
end

function delete()
end

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

        vm = db:prepare(sql)
        if vm:step() == sqlite3.ROW then

            local ctime
            _, _, ctime = vm:get_uvalues()
            diff = os.time() - ctime
            if diff > expire then
                found = false
            else
                found = true
            end
        else
            found = false
        end
        vm:finalize()

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

function update()
end
