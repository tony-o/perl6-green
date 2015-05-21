#!/usr/bin/env perl6

multi sub MAIN(Str $testdir?) {
  my $dir = $testdir;
  if !$dir {
    for ('t', 'test', 'tests') -> $d {
      $dir = $d;
      last if $dir.IO:d;
    }
    "Unable to find test directory: t, test, tests{$testdir ?? ', ' ~ $testdir !! ''}".say, exit 1 unless $dir.IO ~~ :d;
  }

  "Unable to find test directory: $dir".say, exit 1 if $dir.IO !~~ :d;


  my @testfiles = $dir.IO.dir.grep(/ '.t' $ /);
  my @testouts;
  my $START = time;
  
  for @testfiles -> $file {
    my Proc::Async $proc .=new('perl6', '-Iblib', '-Ilib', $file.IO.abspath);
    my $stdout = '';
    my $stderr = '';
    $proc.stdout.tap(-> $v { $stdout ~= $v; });
    $proc.stderr.tap(-> $v { $stderr ~= $v; });
    my $s = $proc.start;
    @testouts.push({ 
      prom => $s,
      proc => $proc,
      out  => sub { $stdout },
      err  => sub { $stderr },
    });
  }

  my Bool $stillgoing = True;
  my Bool $OK         = True;
  my Int  $TOTAL      = 0;
  my Int  $FAILED     = 0;
  while @testouts.elems {
    await Promise.anyof(@testouts.map({ $_<prom> }));
    my ($i, @remove) = 0, ;
    for @testouts -> $t {
      if $t<prom>.status ~~ Kept {
        say $t<out>();
        say $t<err>();
        if $t<prom>.result.exitcode != 0 {
          $FAILED++;
          $OK = False;
        }
        $TOTAL++;
        @remove.push($i);
      }
      $i++;
    }
    @testouts.splice($_, 1) for @remove;
  }
  my $END = time;

  "$TOTAL files tested in {sprintf('%.1f', $END - $START);}s".say;
  "$FAILED of $TOTAL failed tests".say;
  exit 1 unless $OK;
  exit 0;
}
