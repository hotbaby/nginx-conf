#! /usr/bin/env lua

--[[

AUTHENTICATION

--]]

package.path = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local user = require('user')
local json = require('cjson')

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
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return false
    end

    local body_json
    body_json = json.decode(body_block)
    if body_json == nil then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return false
    end

    if body_json['method'] == 'login' then

        ngx.log(ngx.INFO, '@auth@ login rpc.')
        return true
    elseif body_json['method'] == 'ROUTER.isInitial' then

        ngx.log(ngx.INFO, '@auth@ ROUTER.isInitial rpc.')
        return true
    else

        ngx.exit(ngx.HTTP_UNAUTHORIZED)
        return false
    end
end

rpc_auth()
