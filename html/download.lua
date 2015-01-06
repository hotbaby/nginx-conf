#! /usr/bin/env lua

--[[

DOWNLOAD HANDLER

--]]

package.path    = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath   = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local json       = require('cjson')
local error_code = require('error_code')

ngx.status = ngx.HTTP_NOT_FOUND
ngx.header.content_type = 'application/json'

local res = {}
local err = {}

err['code']     = -33201
err['message']  = error_code[err['code']]

res['jsonrpc']  = '2.0'
res['error']    = err
res['id']       = nil

ngx.say(json.encode(res))
ngx.eof()
