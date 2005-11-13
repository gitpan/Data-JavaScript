BEGIN { $| = 1; print "1..2\n"; }
use Data::JavaScript {UNDEF=>0};

#Test undef value overloading

$_ = join('', jsdump('foo', [1,undef,1]));
print 'not ' unless $_ eq
      'var foo = new Array;foo[0] = 1;foo[1] = undefined;foo[2] = 1;';
print "ok 1 #$_\n";

$_ = join('', jsdump('foo', [1,undef,1], 'null'));
print 'not ' unless $_ eq
      'var foo = new Array;foo[0] = 1;foo[1] = null;foo[2] = 1;';

print "ok 2 #$_\n";
