#!/usr/bin/env perl6

use lib 'lib';
use Test;
use Green;

plan 1;

my Green $g .=new;

$g.eval('
my ($t0, $t1);

set(\'s1\', sub {
  test(\'t1\', -> $done {
    $t0 = now;
    sleep 1;
    $done();
  });
  test(\'t2\', -> $done {
    sleep 1;
    $t1 = now;
    $done();
  });
});
');

END {
  await Promise.allof($g.promises);
}
