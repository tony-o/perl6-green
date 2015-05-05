#!/usr/bin/env perl6

use Green;
use Test;

%*ENV<PERL6_GREEN_TIMEOUT> = 500;

:) {
  plan 1;
  ok 1==1;
  sleep 1;
  ok 1==0;
};
