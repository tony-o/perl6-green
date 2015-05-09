module Green;

my @sets;
my ($p0, $i,$i2) = 1, 0, 0;
my Channel $CHANNEL .=new;
my ($pass,$fail)  = '[P]', '[F]';
my $space         = 3;
my $tests         = 0;
my $passing       = 0;
my $t0            = now;
my $supply        = Supply.new;
my $index         = 0;

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

multi sub set(Callable $skip, Callable $sub) is export(:DEFAULT, :harness) {
  set("Suite $i", $skip, $sub);
}

multi sub set(Str @modules, Callable $sub) is export(:DEFAULT, :harness) {
  set("Suite $i", @modules, $sub); 
}

multi sub set(Str $description, Array $modules, Callable $sub) is export(:DEFAULT, :harness) {
  my Bool $add = False;
  try {
    for @($modules) { 
      require ::($_); 
    }
    $add = True;
  };
  set($description, $sub) if $add;
}


multi sub set(Str $description, Block $skip, Callable $sub) is export(:DEFAULT, :harness) {
  my Bool $add = False;
  try {
    $skip.();
    $add = True;
  };
  set($description, $sub) if $add;
}

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
  @promises[$i] = Promise.new;
  $sub();
  await $CHANNEL.send({
    description => $description,
    tests       => @tests,
    promindex   => $i++,
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
  @promises[$i].keep(True);
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


    await start {
      my Str  $output  = '';
      my Str  $errors  = '';
      my Bool $overall = True;
      my $ti = 1;
      for @($set<tests>) -> $test {
        my Bool $success;
        try { 
          $tests++;
          my $promise = Promise.new;
          my $done    = sub { $set<promindex>.say; $promise.keep(True); };
          my $donf    =  ($test<sub>.signature.count == 1 && $test<sub>.signature.params[0].name ne '$_') || ($test<sub>.signature.count > 1);
          await Promise.anyof($promise, start {
            'donf'.say if $donf;
            $test<sub>($done) if  $donf;
            await $promise    if  $donf;
            $test<sub>()      if !$donf;
          });
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
      %results{$set<promindex>} = "{' ' x $space}{$overall ?? $pass !! $fail} $set<description>\n" ~ $output ~ "\n{$errors}{$errors ne '' ?? "\n" !! ''}";
      $supply.emit($set<promindex>);
    }
  }
};


END {
  if @prefixed.elems {
    $CHANNEL.send({
      description => "Prefixed Tests",
      tests       => @prefixed,      
    });
  }
  await Promise.allof(@promises) if @promises.elems;
  $t1 = now;
  say "{' ' x $space}{$passing == $tests ?? $pass !! $fail} $passing of $tests passing ({ sprintf('%.3f', ($t1-$t0)*1000); }ms)" if %results.keys.elems;
}

