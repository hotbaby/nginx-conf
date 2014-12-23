#! /usr/bin/env lua

--[[

AUTHENTICATION

--]]

package.path = '/usr/lib/lua/?.lua;'
package.cpath = '/usr/lib/lua/?.so;'

local user = require('user')
local json = require('cjson')

function authentication()

    ngx.req.read_body()

    local body_block
    body_block = ngx.req.get_body_data()
    if body_block == nil then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return false
    end

    local body_json
    body_json = json.decode(body_block)
    if body_json == nil then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return false
    end

    if body_json['token'] ~= nil then

        local result
        result = user.check(body_json['token'])
        if result == true then
            return true
        else
            ngx.exit(ngx.HTTP_UNAUTHORIZED)
        end
    elseif body_json['method'] == 'login' then

        local token
        local username, password

        username = body_json['params'][1]
        password = body_json['params'][2]

        ngx.log(ngx.INFO, 'username:', username)
        ngx.log(ngx.INFO, 'password:', password)
        token = user.login(username, password)
        if token == nil then

            local res = {}
            local err = {}

            err['message']  = 'username and password do not match'
            err['code']     = 2003

            res['error']    = err
            res['jsonrpc']  = '2.0'
            res['id']       = body_json['id']

            ngx.say(json.encode(res))
            ngx.exit(ngx.HTTP_OK)
            return false
        else
            local res = {}
            res['jsonrpc'] = '2.0'
            res['result']  = token
            res['id']      = body_json['id']
            ngx.say(json.encode(res))
            ngx.exit(ngx.HTTP_OK)

            return true
        end
    else
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
        return false
    end

    return true
end

authentication()
