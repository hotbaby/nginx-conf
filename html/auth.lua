#! /usr/bin/env lua

--[[

AUTHENTICATION

--]]

package.path = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local user = require('user')
local json = require('cjson')
local error_code = require('error_code')

function auth()

    if ngx.var.args == nil then
        return false
    end

    local args = ngx.decode_args(ngx.var.args)
    if args['token'] == nil then
        return false
    else
        local result = user.check(args['token'])
        if result == true then
            return true
        else
            return false
        end
    end
end

local ret = auth()
if ret ~= true then
    ngx.log(ngx.ERR, '@auth@ authenication error.')

    local err = {}
    local res = {}

    err['code']     = -33000
    err['message']  = error_code[err['code']]

    res['jsonrpc']  = '2.0'
    res['error']    = err

    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header.content_type = 'application/json'

    ngx.say(json.encode(res))
    ngx.eof()
end

