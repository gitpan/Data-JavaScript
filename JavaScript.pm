package Data::JavaScript;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Tie::RefHash;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    jsdump hjsdump
);
$VERSION = '1.00';

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
                  "$sym\[$k]");
            push(@list, __jsdump($newsym, $elem->{$k}, $dict));
        }
        return @list;
    }
}

1;
