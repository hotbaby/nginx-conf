#! /usr/bin/env lua

--[[

AUTHENTICATION

--]]

package.path = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local user = require('user')
local json = require('cjson')
local error_code = require('error_code')

function rpc_auth()

    if ngx.var.args ~= nil then
        local args = ngx.decode_args(ngx.var.args)
        if args['token'] ~= nil then
            local result = user.check(args['token'])
            if result == true then
                return true
            end
        end
    end

    ngx.req.read_body()

    local body_block
    body_block = ngx.req.get_body_data()
    if body_block == nil then
        return false
    end

    local body_json
    body_json = json.decode(body_block)
    if body_json == nil then
        return false
    end

    if body_json['method'] == 'login' then

        ngx.log(ngx.INFO, '@rpc_auth@ login rpc.')
        return true
    elseif body_json['method'] == 'ROUTER.isInitial' then

        ngx.log(ngx.INFO, '@rpc_auth@ ROUTER.isInitial rpc.')
        return true
    else

        return false
    end
end

local ret = rpc_auth()
if ret ~= true then
    ngx.log(ngx.ERR, '@rpc_auth@ authenication error.')

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
