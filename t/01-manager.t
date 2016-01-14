use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * 12;

my $pwd = cwd();

$ENV{TEST_LEDGE_REDIS_DATABASE} ||= 1;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_shared_dict test_cache 1m;
};

no_long_string();
run_tests();

__DATA__
=== TEST 1: Can create an instance
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
                ngx.say("Failed to retrieve cache instance")
            else
                ngx.say("OK")
            end
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
OK

=== TEST 2: Must specify a name
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new()
    ';
}

--- request
GET /a
--- must_die

=== TEST 3: Must specify a dictionary
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache")
    ';
}
--- request
GET /a
--- must_die

=== TEST 4: Dictionary must exist
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = foobar})
    ';
}
--- request
GET /a
--- must_die

=== TEST 5: List instances
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
        manager.new("test_cache2", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
                local manager = require("resty.tlc.manager")
                local instances = manager.list()
                for _, i in ipairs(instances) do
                    ngx.say(i)
                end
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
test_cache
test_cache2

=== TEST 6: Delete instances
--- http_config eval
"$::HttpConfig"
. q{
    init_by_lua '
        local manager = require("resty.tlc.manager")
        manager.new("test_cache", {dict = "test_cache"})
        manager.new("test_cache2", {dict = "test_cache"})
    ';
}
--- config
    location /a {
        content_by_lua '
                local manager = require("resty.tlc.manager")
                manager.delete("test_cache")

                local instances = manager.list()
                for _, i in ipairs(instances) do
                    ngx.say(i)
                end
        ';
    }
--- request
GET /a
--- no_error_log
[error]
--- response_body
test_cache2
