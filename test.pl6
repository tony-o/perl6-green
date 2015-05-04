#!/usr/bin/env perl6

use lib 'lib';
use Green;

set(sub {
  sleep 2;
  for ^6 {
    my $s = $_;
    test("$s == 1", sub {
      ok 1==$s;
    });
  }
});

set("description sub", sub {
  test("some test", sub {
    ok 1==1;
  });
});

set("time me", sub {
  test("delay 2", sub {
    sleep 2;
    ok 1==1;
  });
});
set("time me", sub {
  test("delay 2", sub {
    sleep 2;
    ok 1==1;
  });
});
set("time me", sub {
  test("delay 2", sub {
    sleep 2;
    ok 1==1;
  });
});
set("time me", sub {
  test("delay 2", sub {
    sleep 2;
    ok 1==1;
  });
});
