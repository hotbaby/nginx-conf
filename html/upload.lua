#! /usr/bin/env lua

--[[

UPLOAD HANDLER

1. parse form fields.
2. move file.
3. generate json message.
4. send to nginx.

--]]

package.path    = '/usr/lib/lua/?.lua;/www/html/?.lua;./?.lua;'
package.cpath   = '/usr/lib/lua/?.so;/www/html/?.so;./?.so;'

local string, exec, io = string, os.execute, io
local md5  = require"cmd5"
local json = require"cjson"
local fs   = require"nixio.fs"
local error_code = require"error_code"

local upload= {}

function upload.reply(result)
    local dump
    local response = {}

    if result ~= nil then
        response['result'] = result
    else
        local err = {}
        err['code']    = -33100
        err['message'] = error_code[err['code']]
        response['error'] = err
    end

    response['jsonrpc'] = '2.0'
    response['id'] = nil

    dump = json.encode(response)
    ngx.log(ngx.INFO, dump)

    ngx.header['Content-Length'] = string.len(dump)
    ngx.header['Content-Type'] = 'application/json'
    ngx.send_headers()

    ngx.say(dump)
end

function upload.get_form_data(value)
    local result = {}
    local pattern = 'name=%"(.-)%"%\r%\n%\r%\n(.-)%\r%\n'

    if type(value) ~= "string" then
        return nil
    end

    local start = value

    for k, v in string.gmatch(start, pattern) do
        result[k] = v
    end

    return result
end

function upload.parse()
    local args, err
    local file_info_table
    local upload_type

    ngx.req.read_body()

    --[[
    get http headers.
    parse upload type basing on session-id and content-range.
    --]]
    local header = ngx.req.get_headers()
    if header['session-id'] ~= nil
        and (header['x-content-range'] ~= nil
            or header['content-range'] ~= nil) then
        upload_type = 'resumable'
    else
        upload_type = 'form'
    end

    --[[
    get post args and parse form data.
    --]]
    args, err = ngx.req.get_post_args()
    if not args then
        return nil
    end

    s = ''
    for k, v in pairs(args) do
        s = s .. k.. '='.. v
    end

    ngx.log(ngx.INFO, s)
    file_info_table = {}
    file_info_table = upload.get_form_data(s)

    --[[
    if the upload type is 'resumable upload', wrapper the form table again.
    parse 'filename' and 'filepath' from headers.
    --]]
    if string.match(upload_type, 'resumable') then
        local tmp = {}
        local file_name
        local file_path
        local file_name_pattern = 'file=%s*(.*)%;'
        local file_path_pattern = 'path=%s*(.*)'

        header = ngx.req.get_headers()
        file_name = string.match(header['content-disposition'], file_name_pattern)
        file_path = string.match(header['content-disposition'], file_path_pattern)

        tmp['file_size']    = file_info_table['_size']
        tmp['file_name']    = file_name
        tmp['path']         = file_path
        tmp['file_tmp_path'] = file_info_table['_tmp_path']
        tmp['file_md5']     = md5.file_sum(file_info_table['_tmp_path'])
        file_info_table     = tmp
    end

    --[[
    debug file info table.
    --]]
    for k, v in pairs(file_info_table) do
        print('file info table:'.. k..': '..v)
    end

    return file_info_table
end

function upload.upload(form)
    local e
    local ret
    local file_tmp_path, path
    local file_name

    if type(form) ~= 'table' then
        return nil
    end

    path = form['path']
    path = '/home/homecloud/files' .. path
    e = string.sub(path, #path)
    if e ~= '/' then
        path = path .. '/'
    end

    if fs.access(path) ~= true then
        fs.mkdir(path, '775')
    end

    file_name = form['file_name']
    file_tmp_path = form['file_tmp_path']

    file_path = path .. file_name
    while true do
        ret = file_exist(file_path)
        if ret == false then
            break
        end

        local md5_checksum = md5.file_sum(file_path)
        if md5_checksum == form['file_md5'] then
            print('md5 uniformity')
            break
        end

        file_name = file_rename(file_name)
        file_path = path .. file_name
    end

    local name, extention_name, duplicate_num
    name, extention_name, duplicate_num = file_spilt_name(file_name)
    if duplicate_num > 0 then
        if extention_name == nil then
            file_path =  path .. name .. "(" .. tostring(duplicate_num) .. ")"
        else
            file_path =  path .. name .. "(" .. tostring(duplicate_num) .. ")" .. '.' .. extention_name
        end
    end

    local decode_table
    local target_path
    decode_table = ngx.decode_args(file_path, 0)
    for k, v in pairs(decode_table) do
        target_path = k
        break
    end
    ngx.log(ngx.INFO, 'target_path:', target_path)

    local ret
    local result = {}
    ret = fs.move(file_tmp_path, target_path)

    if ret ~= true then
        return nil
    else
        local stat = fs.stat(target_path)
        local path = form['path']
        if string.sub(path, #path) ~= '/' then
            path = path .. '/'
        end

        result['path']  = path .. file_name
        result['fid']   = stat['ino']
        result['ctime'] = stat['ctime']
        result['mtime'] = stat['mtime']
        result['size']  = stat['size']
        result['isdir'] = false
        result['thumbnail'] = ''

        return result
    end

end

function file_exist(path)
    ngx.log(ngx.INFO, 'path:', path)

    if type(path) ~= 'string' then
        return false
    end

    local handle = io.open(path)
    if handle == nil then
        return false
    else
        io.close(handle)
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

result = upload.parse()
if result ~= nil then
    result = upload.upload(result)
    upload.reply(result)
else
    upload.reply(result)
end
ngx.eof()
