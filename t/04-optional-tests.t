#!/usr/bin/env perl6

use Green;
use Test;


my Promise $promise .=new;

my @madeupmodules;

@madeupmodules.push( ("A".."Z").roll(140).join('') ) for ^5;



set('Optional tests never run', { require ::(@madeupmodules); }, {
  test({
    ok 5 == 0;
  });
});

set('This is the first test set to start', {
  test({
    plan 2;
    ok True;
  });
});

set('I don\'t run either', @madeupmodules, {
  test({
    ok True;
  });
});

set('I do tho!', ['Test'], {
  test({
    ok True;
  });
});

