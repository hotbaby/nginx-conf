#! /usr/bin/env lua

local user = require('user')

local token = user.login('homecloud', '1')
print(type(token))
print(token)

local result = user.check('c22530da89cf11e4b1a499de58cae642')
print(result)
