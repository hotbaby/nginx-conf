#! /usr/bin/env lua

--[[

    UPLOAD HANDLER

    1. parse form fields.
    2. move file.
    3. generate json message.
    4. send to nginx.

--]]

local string, exec, io = string, os.execute, io
local md5  = require"cmd5"
local json = require"cjson"

local upload_handler = {}

function upload_handler.set_handers()
    ngx.req.set_header("Content-Type", "text/plain")
    return true
end

function upload_handler.reply(result, err)
    local dump
    local response = {}

    if result ~= nil then
        response['result'] = result
    else
        response['error'] = err
    end

    response['jsonrpc'] = '2.0'
    response['id'] = nil


    dump = json.encode(response)
    ngx.log(ngx.INFO, dump)

    return ngx.say(dump)
end

--[[
    TODO
    whether the regular expressions can match completely or not.
--]]
function upload_handler.get_form_data(value)
    local result = {}
    local pattern = 'name=%"[%w_]*%"%\r%\n%\r%\n[/%w%.%-]*%\r%\n'

    if type(value) ~= "string" then
        return nil
    end

    local start = value

    local s, e
    local key, val
    for w in string.gmatch(start, pattern) do
        s,e = string.find(w, 'name=%"[%w_]*%"')
        key = string.sub(w, s+6, e-1)

        s,e = string.find(w, '%\r%\n%\r%\n[/%w%.%-]*%\r%\n')
        val = string.sub(w, s+4, e-2)

        result[key] = val
    end

    return result
end

function upload_handler.parse()
    local args, err
    local result, error_code

    ngx.req.read_body()

    args, err = ngx.req.get_post_args()
    if not args then
        return nil
    end

    s = ''
    for key, val in pairs(args) do
        s = s .. key .. '='.. val
    end

    result = {}
    result = upload_handler.get_form_data(s)

    error_code = nil

    return result, error_code
end

function upload_handler.upload(form)
    local e
    local ret
    local cmd
    local file_tmp_path, path
    local file_name

    if type(form) ~= 'table' then
        return nil
    end

    path = form['path']
    e = string.sub(path, #path)
    if e ~= '/' then
        path = path .. '/'
    end

    file_name = form['file_name']
    file_tmp_path = form['file_tmp_path']

    file_path = path .. file_name
    while true do
        ret = file_exist(file_path)
        if ret == false then
            break
        end


        file_name = file_rename(file_name)
        file_path = path .. file_name
    end

    local name, extention_name, duplicate_num
    name, extention_name, duplicate_num = file_spilt_name(file_name)
    if duplicate_num > 0 then
        if extention_name == nil then
            file_path =  name .. "'('" .. tostring(duplicate_num) .. "')'"
        else
            file_path =  name .. "'('" .. tostring(duplicate_num) .. "')'"
                        .. '.' .. extention_name
        end
    end

    cmd = 'mv'.. ' ' .. file_tmp_path .. ' ' .. file_path
    ngx.log(ngx.INFO, 'cmd:', cmd)
    exec(cmd)

    return form
end

function file_exist(path)
    ngx.log(ngx.INFO, 'path:', path)

    if type(path) ~= 'string' then
        return false
    end

    --[[
    local name, extention_name
    local duplicate_num

    name, extention_name, duplicate_num = file_spilt_name(path)
    if duplicate_num > 0 then
        if extention_name == nil then
            path = name .. '(' .. tostring(duplicate_num) .. ')'
        else
            path = name .. '(' .. tostring(duplicate_num) .. ')' .. '.' ..extention_name
        end
    end
    --]]

    local h = io.open(path)
    if h == nil then
        return false
    else
        io.close(h)
        return true
    end
end

function file_rename(file_name)
    local ret
    local duplicate_num
    local name, extention_name

    if type(file_name) ~= 'string' then
        return file_name
    end

    name, extention_name, duplicate_num = file_spilt_name(file_name)
    duplicate_num = duplicate_num + 1

    if extention_name == nil then
        file_name = name .. '(' .. tostring(duplicate_num) .. ')'
    else
        file_name = name .. '(' .. tostring(duplicate_num) .. ')' .. '.' ..extention_name
    end

    return file_name
end

function file_find_duplicate_number(str)
    local number
    local s, e
    local pattern = "%(%d*%)"

    s, e = string.find(str, pattern)
    if s == nil then
        return 0
    end

    number = string.sub(str, s+1, e-1)
    number = tonumber(number)

    return number, s, e
end

--[[
    reverse find slit symbol '.'
--]]
function file_reverse_find_split_symbol(str)
    if type(str) ~= 'string' then
        return nil
    end

    local split = '%.'
    local reverse_str
    local reverse_start
    local len

    len = string.len(str)
    reverse_str = string.reverse(str)

    reverse_start, _= string.find(reverse_str, split)
    if reverse_start == nil then
        return nil
    end

    return len-reverse_start+1
end

function file_spilt_name(str)
    local name, extention_name
    local duplicate_num

    if type(str) ~= 'string' then
        return nil
    end

    local split_start
    split_start = file_reverse_find_split_symbol(str)
    if split_start == nil then
        name = str
        extention_name = nil
    else
        name = string.sub(str, 1, split_start-1)
        extention_name = string.sub(str, split_start+1, #str)
    end

    local duplicate_num
    local duplicate_start
    duplicate_num, duplicate_start = file_find_duplicate_number(str)
    if duplicate_num == 0 then
    else
        name = string.sub(str, 1, duplicate_start-1)
    end

    return name, extention_name, duplicate_num
end

local result = {}
local error_code

upload_handler.set_handers()

result, error_code = upload_handler.parse()
if result ~= nil then
    result, error_code = upload_handler.upload(result)
    upload_handler.reply(result, error_code)
else
    upload_handler.reply(result, error_code)
end

