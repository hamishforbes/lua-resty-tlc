# lua-resty-tlc

Two Layer Cache implementation using [lua-resty-lrucache](https://github.com/openresty/lua-resty-lrucache) and [shared dictionaries](https://github.com/openresty/lua-nginx-module#ngxshareddict).

Cache entries are written to lru-cache in the current worker and to a shared dictionary.

Cache reads that miss in the worker's lru-cache instance are re-populated from the shared dictionary if available.

Values in shared dictionaries are automatically serialised and unserialised to JSON (custom serialisation functions are supported)

Also provides a manager module to maintain global set of TLC cache instances

# Overview

```lua
lua_package_path "/path/to/lua-resty-tlc/lib/?.lua;;";

lua_shared_dict tlc_cache 10m;
lua_shared_dict tlc_cache2 1m;

init_by_lua_block {
    local manager = require("resty.tlc.manager")
    manager.new("my_cache", {size = 500, dict = "tlc_cache"})

    manager.new("my_cache2", {size = 500, dict = "tlc_cache2"})
}


location = /get {
    content_by_lua_block {
        local manager = require("resty.tlc.manager")
        local cache = manager.get("my_cache")

        local args = ngx.req.get_uri_args()
        local key = args["key"]

        local data, err = cache:get(key)
        if err then
            ngx.log(ngx.ERR, err)
        elseif data == nil then
            ngx.status = ngx.HTTP_NOT_FOUND
            ngx.say("Not Found")
        else
            ngx.say(tostring(data))
        end
    }
}

location = /set {
    content_by_lua_block {
        local manager = require("resty.tlc.manager")
        local cache = manager.get("my_cache")

        local args = ngx.req.get_uri_args()
        local key = args["key"]
        local val = args["val"] or { foo = bar }
        local ttl = args["ttl"]

        local ok, err = cache:set(key, val, ttl)
        if not ok then
            ngx.log(ngx.ERR, err)
        end
    }
}

location = /flush {
    content_by_lua_block {
        local manager = require("resty.tlc.manager")
        local cache = manager.get("my_cache")
        cache:flush()
    }
}

location = /list {
    content_by_lua_block {
        local manager = require("resty.tlc.manager")
        local instances = manager.list()

        ngx.say(require("cjson").encode(instances))
    }
}


```

# Methods

* [manager](#manager)
 * [new](#new)
 * [get](#get)
 * [set](#set)
 * [delete](#delete)
 * [list](#list)
* [cache](#cache)
 * [new](#new-1)
 * [set](#set-1)
 * [get](#get-1)
 * [delete](#delete-1)
 * [flush](#flush)

## manager

### new
`syntax: ok, err = manager.new(name, opts)`

Create a new `resty.tlc.cache` instance with given name/id and options.

Will **not** check if instance already exists, existing instances will be overwritten

### get
`syntax: cache = manager.get(name)`

Returns the specified TLC cache instance or nil

### delete
`syntax: manager.delete(name)`

Removes the specified cache instance.

### list
`syntax: instances = manager.list()`

Returns an array table of available cache instances

## cache

### new
`syntax: instance = cache:new(opts)`

Creates a new instance of `resty.tlc.cache`, `opts` is a table of options for this instance.

```lua
opts = {
    dict         = dict,         -- Shared dictionary name, required
    size         = size,         -- max_items parameter for LRU cache, optional, default 200
    pureffi      = pureffi,      -- Use the pureffi LRU cache variant, optional, default false
    loadfactor   = loadfactor,   -- Load factor for pureffi LRU cache, optional
    serialiser   = serialiser,   -- Function to serialise values when saving to shared dictionary, optional, defaults to pcall'd cjson encode
    unserialiser = unserialiser, -- Function to unserialise values when saving to shared dictionary, optional, defaults to pcall'd cjson decode
}
```

Functions to serialise and unserialise should `return nil, err` on failure.

### set
`syntax: ok, err = cache:set(key, value, ttl?)`

Set or update an entry in the cache.

`ttl` is optional and in seconds


### get
`syntax: data = cache:get(key)`

Returns data from cache or `nil` if not set


### delete
`syntax: cache:delete(key)`

Deletes entry from both LRU cache and shared dictionary

TODO: Delete from LRU cache in all workers

### flush
`syntax: cache:flush(hard?)`

Re-initialises LRU cache in current worker and flushes shared dictionary.

`hard` argument will also call `flush_expired()` on dictionary.

TODO: Re-initialise LRU cache in all workers


# TODO

* Add feature to ngx_lua shared dictionary to retrieve remaining TTL of entry
* Syncronise LRU cache delete / flush across workers

