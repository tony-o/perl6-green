#!/usr/bin/env perl6

use Test;

my $server = IO::Socket::INET.new(:localhost<127.0.0.1>, :localport(8091), :listen);
my $supply = Supply.new;
my $conn;

my $promise = start({
  $conn = $server.accept;
  $supply.emit($conn);
});

$supply.tap(-> $conn {
  my $data = '';
  'Starting to receive.'.say;
  while my $d = $conn.recv {
    $data ~= $d;
  }
  'Never get\'s to this line.'.say;
  ok $data eq 'Hello, perl6.';
});

my $cconn = IO::Socket::INET.new(:host<127.0.0.1>, :port(8091));
'Connection sending data.'.say;
$cconn.send('Hello, perl6.');

await $promise;
