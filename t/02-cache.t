use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * 51;

my $pwd = cwd();

$ENV{TEST_LEDGE_REDIS_DATABASE} ||= 1;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_shared_dict test_cache 1m;
};

no_long_string();
run_tests();

__DATA__
=== TEST 1: Set and retrieve value
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        local cache = manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Turn on debug mode
            cache._debug(true)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Found key 'test_key' in LRU cache
--- response_body
test_val


=== TEST 2: Get value from shared dict
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            -- Turn on debug mode
            cache._debug(true)

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)


            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Found key 'test_key' in shared dictionary
--- response_body
test_val


=== TEST 3: Delete value
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            cache:delete("test_key")

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
nil

=== TEST 4: Delete value - shared dict
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end


            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)

            cache:delete("test_key")

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
nil

=== TEST 5: Flush value
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            cache:flush()

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
nil

=== TEST 6: Flush value - shared dict
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)

            cache:flush()

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
nil

=== TEST 7: Set and retrieve serialisable value
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            -- Turn on debug mode
            cache._debug(true)

            local ok, err = cache:set("test_key", {foo = "bar"})
            if not ok then
                return ngx.say(err)
            end

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            for k,v in pairs(data) do
                ngx.say(k)
                ngx.say(v)
            end
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Serialised
--- response_body
foo
bar

=== TEST 8: Set and retrieve serialisable value - shared
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", {foo = "bar"})
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)
            -- Turn on debug mode
            cache._debug(true)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            for k,v in pairs(data) do
                ngx.say(k)
                ngx.say(v)
            end
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Unserialised
--- response_body
foo
bar

=== TEST 9: Values expire
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val", 1)
            if not ok then
                return ngx.say(err)
            end

            ngx.sleep(1.5)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
nil

=== TEST 10: Flush value - hard
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Turn on debug mode
            cache._debug(true)

            cache:flush(true)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log_like
Flushed \d+ keys from memory
--- response_body
nil

=== TEST 11: Override serialiser / unserialiser
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '

        local serialiser = function(input) return "Serialised string!" end
        local unserialiser = function(input) return "Unserialised string!" end

        local manager = require("resty.tlc.manager")
        manager.new("test_cache",
            {
                dict = "test_cache",
                serialiser = serialiser,
                unserialiser = unserialiser
            })
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", {"foo", "bar"})
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)

            local data2 = cache.dict:get("test_key")
            ngx.say(data2)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
Unserialised string!
Serialised string!

=== TEST 12: Set and retrieve value - pureffi
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        local cache = manager.new("test_cache", {dict = "test_cache", pureffi = true})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Turn on debug mode
            cache._debug(true)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Found key 'test_key' in LRU cache
--- response_body
test_val

=== TEST 13: Repopulated lru entries expire
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            -- Turn on debug mode
            cache._debug(true)

            local ok, err = cache:set("test_key", "test_val", 1)
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)

            cache:get("test_key")

            ngx.sleep(1.5)

            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Repopulated lru cache
Key 'test_key' not found in LRU cache: test_val
--- response_body
nil

=== TEST 14: LRU Cache is repopulated from shared dict
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
            local manager = require("resty.tlc.manager")
            local cache = manager.get("test_cache")
            if not cache then
                return ngx.say("Failed to retrieve cache instance")
            end

            local ok, err = cache:set("test_key", "test_val")
            if not ok then
                return ngx.say(err)
            end

            -- Init a new lrucache instance
            local lrucache = require("resty.lrucache")
            cache.lru = lrucache.new(10)

            -- Turn on debug mode
            cache._debug(true)

            -- should repopulate lru cache
            cache:get("test_key")


            local data, err = cache:get("test_key")
            if err then
                return ngx.say("ERR: ", err)
            end
            ngx.say(data)
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- error_log
Repopulated lru cache
Found key 'test_key' in LRU cache
--- response_body
test_val
