use Data::JavaScript {UNDEF=>0};

print "1..2\n";

print 'not' unless join('', jsdump('foo', [1,undef,1])) eq
      'var foo = new Array;foo[0] = 1;foo[1] = 0;foo[2] = 1;';
print "ok 1\n";

print 'not' unless join('', jsdump('foo', [1,undef,1], 'null')) eq
      'var foo = new Array;foo[0] = 1;foo[1] = null;foo[2] = 1;';

print "ok 2\n";
