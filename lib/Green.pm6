class Green;

has Channel $.tester   .= new;
has Supply  $.results  .= new;
has Promise $.complete .= new;
has Bool    $!tested    = False;
has Int     $.space     = 2;

has @.promises;

has %.stats = 
  start            => 0,
  end              => 0,
  tests            => 0, 
  successful-tests => 0,
  sets             => 0,
  errors           => @(),
;


method !tester {
  return if $!tested;
  $!tested = True;
  start {
    loop {
      my Bool $pass = False;
      my Int  $err  = 1;
      my      $set  = $.tester.receive;
      for @($set<tests>) -> $test {
        %.stats<tests>++;
        try {
          my Bool $async = ($test<sub>.signature.count == 1 
                              && $test<sub>.signature.params[0].name ne '$_') 
                           || ($test<sub>.signature.count > 1);
          if $async {
            my Promise $promise .= new;
            $test<sub>(sub {
              $promise.keep(True);
            });
            await $promise;
          } else {
            $test<sub>();
          }
          %.stats<successful-tests>++;
          $pass = True;
          CATCH {
            default {
              'error'.say;
              %.stats<errors>.push("{' ' x ($.space*2)}#{$err++} - {$_.Str}\n{
                try $_.backtrace.Str.lines.map({
                  .subst(/ ^ \s+ /, ' ' x ($.space*3))
                }).join("\n")}\n");
            }
          }
        };
      }
      $set<promise>.keep(True);
    };
  };
}


method eval($str) {

  my $self = self;
  my %sets;

  multi sub set(Callable $sub) {
    set("Set {$self.stats<sets>}", $sub);
  }


  multi sub set(Str $description, Callable $sub) {
    %sets{$description} = {
      tests   => @(),
      promise => Nil,
    } unless defined %sets{$description};
    $sub();
  }

  multi sub test(Callable $sub) is export { 
    test("Test {$self.stats<tests>}", $sub); 
  };
  multi sub test (Str $d, Callable $s) is export { 
    $self.stats<tests>++;
    my $frame = 0;
    while !callframe($frame).my<$description>.defined {
      $frame++;
    }
    "for $d".say;
    "{$*SET // 'undef'} :: $d".say;
  }

  EVAL $str;
}
