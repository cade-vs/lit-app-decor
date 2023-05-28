#!/usr/local/bin/plackup --no-default-middleware
# remove --no-default-middleware to allow client-side web browser debug
use strict;
use lib '/usr/local/decor/easy/lib';
use lib '/usr/local/decor/web/lib';
use lib '/usr/local/decor/shared/lib';
use Web::Reactor::Decor;
use Data::Dumper;
use Time::HR;

# $| = 1;
# $Data::Dumper::Sortkeys = 1;
# print STDERR  "\n" x 10;

my $DECOR_APP_NAME  = 'lit';
my $DECOR_APP_ROOT  = '/usr/local/decor/apps/lit-app-decor';
my $DECOR_CORE_ROOT = '/usr/local/decor';

my $cfg = {
            APP_NAME               => $DECOR_APP_NAME,
            DECOR_CORE_ROOT        => $DECOR_CORE_ROOT,
            DECOR_CORE_HOST        => 'localhost:42000',
            DECOR_CORE_APP         => $DECOR_APP_NAME,
            DEBUG                  => 1,
            LANG                   => 'en',
            SESS_VAR_DIR           => "$DECOR_CORE_ROOT/easy/var/web",
            DISABLE_SECURE_COOKIES => 0,

            # USER_SESSION_EXPIRE => 1209600, # 2 weeks in seconds, default is 600, i.e. 10 minutes
          
            # default formats
            # FMT_DATE  => 'DMY',
            # FMT_TIME  => '24HS',
            # FMT_UTIME => 'DMY24S',
          };

sub
{
    my $env = shift;
 
    my $res;
    eval
      {
      $res = Web::Reactor::Decor->new( $env, $cfg )->run();
      };
    if( $@ or ! $res )
      {
      print STDERR "REACTOR EXCEPTION: $@";
      $res = [ 200, [ 'content-type' => 'text/plain' ], [ 'system is currently unavailable' ] ];
      }
 
    return $res;
};
