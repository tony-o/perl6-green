unit module Green;

my @sets;
my ($p0, $i,$i2) = 1, 0, 0;
my Channel $CHANNEL .=new;
my ($pass,$fail)  = '[P]', '[F]';
my $space         = 3;
my $tests         = 0;
my $passing       = 0;
my $t0            = now;
my $supply        = Supply.new;
my $tsets         = 0;
my $csets         = 0;
my $completion    = Promise.new;
my $t1;

my $MS            = %*ENV<PERL6_GREEN_TIMEOUT> // 3600000;

my @promises;
my %results;


my @prefixed;

multi sub prefix:<\>\>>(Bool $bool) is export(:DEFAULT, :harness) {
  @prefixed.push({
    test => "Prefixed {$p0++}",
    sub  => sub { die 'not ok' unless $bool; },
  });
};

multi sub prefix:<\>\>>(Callable $sub) is export(:DEFAULT, :harness) { 
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
  $tsets++;
  $CHANNEL.send({
    description => $description,
    tests       => @tests,
  });
}

sub ok (Bool $eval) is export(:harness) {
  if $?CALLER::PACKAGE ~~ GLOBAL {
    >> $eval;
    return;
  }
  die 'not ok' unless $eval;
}


$supply.tap(-> $i {
  try print %results{$i};
  $completion.keep(True) if $tsets == ++$csets;
});

start {
  loop {
    my $set = $CHANNEL.receive;
    my ($err, $index) = 1, 1;
    try {
      require Term::ANSIColor;
      $pass = '[' ~ Term::ANSIColor.color('green') ~ ' OK ' ~ Term::ANSIColor.color('reset') ~ ']';
      $fail = '[' ~ Term::ANSIColor.color('red') ~ 'FAIL' ~ Term::ANSIColor.color('reset') ~ ']';
    };


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
          my $promise = Promise.new;
          my $done    = sub { $promise.keep(True); };
          my $donf    =  ($test<sub>.signature.count == 1 && $test<sub>.signature.params[0].name ne '$_') || ($test<sub>.signature.count > 1);
          await Promise.anyof($promise, start {
            $test<sub>($done) if  $donf;
            await $promise    if  $donf;
            $test<sub>()      if !$donf;
          });
          #die "Timeout (test in excess of {$MS}ms)" if $timeout.status ~~ Kept; 
          $passing++;
          $success = True;
          CATCH { 
            default {
              $overall = False;
              $success = False; 
              $errors ~= "{' ' x $space*2}#$err - " ~ $_.Str ~ "\n";
              $errors ~= try $_.backtrace.Str.lines.map({ 
                .subst(/ ^ \s+ /, ' ' x ($space*3)) 
              }).join("\n") ~ "\n"; 
            }
          }
        };
        try $output ~= "{' ' x $space*2}{$success ?? $pass !! $fail ~ " #{$err++} - " } $test<test>\n"; 
      }
      %results{$i} = "{' ' x $space}{$overall ?? $pass !! $fail} $set<description>\n" ~ $output ~ "\n{$errors}{$errors ne '' ?? "\n" !! ''}";
      $supply.emit($i);
    });
  }
};

END {
  if @prefixed.elems {
    $tsets++;
    $CHANNEL.send({
      description => "Prefixed Tests",
      tests       => @prefixed,      
    });
  }

  await $completion if $tsets != 0;
  $t1 = now;
  say "{' ' x $space}{$passing == $tests ?? $pass !! $fail} $passing of $tests passing ({ sprintf('%.3f', ($t1-$t0)*1000); }ms)" if %results.keys.elems;
};
