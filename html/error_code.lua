#! /usr/bin/env lua

--[[

ERROR_CODE MODULE

--]]

package.path    = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath   = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

module('error_code', package.seeall)

error_code = {}

--[[
Upload error code.
range: -33100 ~ -33199
--]]
error_code[-33100] = 'Upload error'

--[[
Download error code.
range: -33200 ~ -33299
--]]
error_code[-33200] = 'Download error'
error_code[-33201] = 'Resource not found'

return error_code
