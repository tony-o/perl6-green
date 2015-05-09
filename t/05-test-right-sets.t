#!/usr/bin/env perl6

use Test;
use Green;

my Green $g .= new;

$g.eval([q|
  my $promise;
  set("set 1", {
    $promise = start {
      sleep 1;
      test("t1.1", {
        say "Set 1, t1.1";
      });
    };
  });

  set("set 2", {
    test("t2.1", {
      say "Set 2, t2.1";
    });
  });

  await $promise;
|]);


