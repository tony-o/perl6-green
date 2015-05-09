#!/usr/bin/env perl6

use lib '../lib';
use Green :harness;


set('only run this test if *ALL* require ::($_) succeed', ['Test'], sub {
  test('Sleep 1', -> {
    ok 1==1;
  });
});

set('This never runs unless you have a module named 1234567890', ['1234567890'], sub {
  test('Sleep 1', -> {
    ok 1==1;
  });
});

set('You can pass callables in too', { die 'this never runs'; }, sub {
  test('never run', -> {
    ok 1 == 0;
  });
});

sub check {
  return False;
}

set('Passing callable is one that doesn\'t die', &check, sub {
  test('I do run!', -> {
    ok 1 == 1;
  });
});
