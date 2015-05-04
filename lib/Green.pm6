module Green;

my @sets;
my ($i,$i2) = 0, 0;

multi sub set(Callable $sub) is export { set("Suite $i", $sub); }

multi sub set(Str $description, Callable $sub) is export {
  my $test = 0;
  my @tests;
  my multi sub test(Callable $sub) is export { test("Test $i2", $sub); };
  my multi sub test(Str $description, Callable $sub) is export {
    $i2++;
    @tests.push({
      test => $description,
      sub  => $sub,
    });
  };
  $i++;
  $sub();
  @sets.push({
    description => $description,
    tests       => @tests,
  });
}

sub ok (Bool $eval) is export {
  die 'not ok' unless $eval;
}

END {
  my @promises;
  my @results;
  my ($err, $index) = 1, 1;
  my ($pass,$fail)  = '[P]', '[F]';
  my $space         = 3;
  my $tests         = 0;
  my $passing       = 0;
  my $t0            = now;
  my $t1;
  for @sets -> $set {
    my $i = @promises.elems;
    @promises.push: start {
      my Str  $output  = '';
      my Str  $errors  = '';
      my Bool $overall = True;
      my $ti = 1;
      for @($set<tests>) -> $test {
        my Bool $success;
        try { 
          $tests++;
          if $test<sub>.signature.count == 1 {
            my $promise = Promise.new;
            my $timeout = Promise.in(2);
            my $done    = sub { $promise.keep(True); };
            $test<sub>($done);
            await Promise.anyof($promise, $timeout);
            die "Timeout (test in excess of 2000 ms)" if $timeout ~~ Kept; 
          } else {
            $test<sub>();
          }
          $success = True;
          CATCH { 
            default {
              $overall = False;
              $success = False; 
              $errors ~= "{' ' x $space*2}#$err - " ~ $_.payload ~ "\n";
              $errors ~= $_.backtrace.Str.lines.map({ .subst(/ ^ \s+ /, ' ' x $space*3) }).join("\n") ~ "\n"; 
            }
          }
        };
        $passing++ if $success;
        $output ~= "{' ' x $space*2}{$success ?? $pass !! $fail ~ " #{$err++} - " } $test<test>\n"; 
      }
      @results[$i] ~= "{' ' x $space}{$overall ?? $pass !! $fail} $set<description>\n" ~ $output ~ "\n$errors\n";
    };
  }
  await Promise.allof(@promises);
  $t1 = now;
  for @results -> $result {
    print $result;
  }
  say "{' ' x $space}{$passing == $tests ?? $pass !! $fail} $passing of $tests passing ({ sprintf('%.3f', ($t1-$t0)*1000); }ms)";
};
