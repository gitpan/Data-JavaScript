package Data::JavaScript;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Tie::RefHash;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    jsdump hjsdump
);
$VERSION = '1.03';

sub jsdump {
    my $sym = shift;
    return "var $sym;\n" unless (@_);
    my $elem = $#_ ? [@_] : $_[0];
    my %dict;
    tie %dict, 'Tie::RefHash';
    my @res = __jsdump($sym, $elem, \%dict);
    $res[0] = "var " . $res[0];
    wantarray ? @res : join("\n", @res, "");
}

sub hjsdump {
    my @code = &jsdump(@_);
    my @res = ('<SCRIPT LANGUAGE="JavaScript1.2">','<!--',
                   @code, '// -->', '</SCRIPT>');
    wantarray ? @res : join("\n", @res, "");
}

sub __jsdump {
    my ($sym, $elem, $dict) = @_;
    unless (ref($elem)) {
        if ($elem =~ /^-?(\d+\.?\d*|\.\d+)([eE]-?\d+)?$/) {
            return "$sym = " . eval($elem) . ";";
        }
        return "$sym = '" . quotemeta($elem) . "';";
    }

    if ($dict->{$elem}) {
        return "$sym = " . $dict->{$elem} . ";";
    }
    $dict->{$elem} = $sym;

    if (UNIVERSAL::isa($elem, 'ARRAY')) {
        my @list = ("$sym = new Array;");
        my $n = 0;
        foreach (@$elem) {
            my $newsym = "$sym\[$n]";
            push(@list, __jsdump($newsym, $_, $dict));
            $n++;
        }
        return @list;
    }

    if (UNIVERSAL::isa($elem, 'HASH')) {
        my @list = ("$sym = new Object;");
        my ($k, $v);
        foreach $k (keys %$elem) {
            $k = quotemeta($k);
            my $newsym = (($k =~ /^\w+$/) ? "$sym.$k" : 
                  "$sym\['$k']");
            push(@list, __jsdump($newsym, $elem->{$k}, $dict));
        }
        return @list;
    }
}


1;
__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Data::JavaScript - Perl extension for dumping structures into JavaScript
code

=head1 SYNOPSIS

  use Data::JavaScript;
  
  @code = jsdump($array_ref, 'my_array');
  $code = jsdump($hash_ref, 'my_object');
  $code = hjsdump($array_ref B<or> $hash_ref, 'my_stuff');

=head1 DESCRIPTION

This module is aimed mainly for CGI programming, when a perl script
generates a page with client side JavaScript code that needs access to
structures created on the server.

It works by creating one line of JavaScript code per datum. Therefore,
structures cannot be created anonymously and needed to be assigned to
variables. This enables dumping big structures.

The first arguement is a hashref or arrayref. Structures can be nested,
circular referrencing is supported EXPERIMENTALLY only.
The second argument is the name of JavaScript object to create.

hsdump also dumps HTML tags to embed the scriplet inside an HTML page.

When called in array context, the functions return an array of code
lines. When called in scalar context, it returns one chunk of lines
delimited by line fields.

=head1 AUTHOR

Ariel Brosh, schop@cpan.org. Inspired by WDDX.pm JavaScript support.

=head1 SEE ALSO

perl(1), L<WDDX>.

=cut
