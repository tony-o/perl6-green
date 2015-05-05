module Green;

my @sets;
my ($p0, $i,$i2) = 1, 0, 0;


my @prefixed;

multi sub prefix:<:)>(Bool $bool) is export(:DEFAULT, :harness) {
  @prefixed.push({
    test => "Prefixed {$p0++}",
    sub  => sub { die 'not ok' unless $bool; },
  });
};

multi sub prefix:<:)>(Callable $sub) is export(:DEFAULT, :harness) { 
  @prefixed.push({ 
    test => "Prefixed {$p0++}", 
    sub  => $sub,
  });
};

multi sub set(Callable $sub) is export(:DEFAULT, :harness) { set("Suite $i", $sub); }

multi sub set(Str $description, Callable $sub) is export(:DEFAULT, :harness) {
  my $test = 0;
  my @tests;
  my multi sub test(Callable $sub) is export(:DEFAULT, :harness) { test("Test $i2", $sub); };
  my multi sub test(Str $description, Callable $sub) is export(:DEFAULT, :harness) {
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

sub ok (Bool $eval) is export(:harness) {
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

  my $MS            = %*ENV<PERL6_GREEN_TIMEOUT> // 3600000;

  "timeout: $MS".say;

  if @prefixed.elems {
    @sets.push({
      description => "Prefixed Tests",
      tests       => @prefixed,      
    });
  }

  for @sets -> $set {
    my $i = @promises.elems;
    @promises.push(start {
      my Str  $output  = '';
      my Str  $errors  = '';
      my Bool $overall = True;
      my $ti = 1;
      for @($set<tests>) -> $test {
        my Bool $success;
        try { 
          $tests++;
          my $timeout = Promise.in($MS/1000);
          my $promise = Promise.new;
          my $donef   = ($test<sub>.signature.count == 1 && $test<sub>.signature.params[0].name ne '$_') ||
                        ($test<sub>.signature.count > 1);
          my $done    = sub { $promise.keep(True); };
          $promise = start { 
            $test<sub>($done) if $donef;
            $test<sub>() unless $donef; 
          };
          await Promise.anyof($promise, $timeout);
          die "Timeout (test in excess of {$MS}ms)" if $timeout.status ~~ Kept; 
          $success = True;
          CATCH { 
            default {
              $overall = False;
              $success = False; 
              $errors ~= "{' ' x $space*2}#$err - " ~ $_.Str ~ "\n";
              $errors ~= $_.backtrace.Str.lines.map({ .subst(/ ^ \s+ /, ' ' x $space*3) }).join("\n") ~ "\n"; 
            }
          }
        };
        $passing++ if $success;
        $output ~= "{' ' x $space*2}{$success ?? $pass !! $fail ~ " #{$err++} - " } $test<test>\n"; 
      }
      @results[$i] ~= "{' ' x $space}{$overall ?? $pass !! $fail} $set<description>\n" ~ $output ~ "\n$errors\n";
    });
  }
  await Promise.allof(@promises) if @promises.elems;
  $t1 = now;
  for @results -> $result {
    print $result;
  }
  say "{' ' x $space}{$passing == $tests ?? $pass !! $fail} $passing of $tests passing ({ sprintf('%.3f', ($t1-$t0)*1000); }ms)" if @results.elems;
};
