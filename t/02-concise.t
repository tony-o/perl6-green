#!/usr/bin/env perl6

use Green :shorthand;
use Test;


my $i = 0;

>> {
  'ere'.say;
  plan 3;
  ok 1 == ++$i;
};

>> {
  ok 2 == ++$i;
}

>> {
  ok 3 == ++$i;
}

{
  $Green::GREEN.stats.perl.say;;
}
