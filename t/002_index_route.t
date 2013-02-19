use Test::More tests => 2;
use strict;
use warnings;
use lib qw(/srv/www/sbcat/PUBSearch/lib);

# the order is important
use PUBSearch;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is [GET => '/'], 200, 'response status is 200 for /';
