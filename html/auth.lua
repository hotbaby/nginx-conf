#! /usr/bin/env lua

--[[

AUTHENTICATION

--]]

package.path = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local user = require('user')

function auth()

    if ngx.var.args == nil then
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
        return false
    end

    local args = ngx.decode_args(ngx.var.args)
    if args['token'] == nil then
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    else
        local result = user.check(args['token'])
        if result == true then
            return true
        else
            ngx.exit(ngx.HTTP_UNAUTHORIZED)
        end
    end
end

auth()

