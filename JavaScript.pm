package Data::JavaScript;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $UNDEF);
use subs qw(quotemeta);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(jsdump hjsdump);

$VERSION = 1.07;
$UNDEF = q('');

sub import{
  foreach( grep{ref($_)} @_ ){
    if(ref($_) eq 'HASH'){
      if(exists($_->{UNDEF})){
	$UNDEF = $_->{UNDEF};
      }
    }
  }
  Data::JavaScript->export_to_level(1, grep {!ref($_)} @_);
}

sub quotemeta {
	my $text = CORE::quotemeta(shift);
	$text =~ s/\\ / /g;
	$text =~ s/\\([^\x20-\x7E])/sprintf("\\%03o", ord($1))/ge;
	$text;
}

sub jsdump {
    my $sym  = shift;
    return "var $sym;\n" unless (@_);
#    my $elem = $#_ ? [@_] : $_[0];
    my $elem  = shift;
    my $undef = shift;
    my %dict;
    my @res   = __jsdump($sym, $elem, \%dict, $undef);
    $res[0]   = "var " . $res[0];
    wantarray ? @res : join("\n", @res, "");
}

sub hjsdump {
    my @res = ('<SCRIPT LANGUAGE="JavaScript1.2">','<!--',
	       &jsdump(@_), '// -->', '</SCRIPT>');
    wantarray ? @res : join("\n", @res, "");
}

sub __jsdump {
    my ($sym, $elem, $dict, $undef) = @_;
    unless (ref($elem)) {
      if(! defined($elem) ){
	return "$sym = @{[defined($undef) ? $undef : $UNDEF]};";
      }
      elsif ($elem =~ /^-?(\d+\.?\d*|\.\d+)([eE]-?\d+)?$/) {
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
            push(@list, __jsdump($newsym, $_, $dict, $undef));
            $n++;
        }
        return @list;
    }

    if (UNIVERSAL::isa($elem, 'HASH')) {
        my @list = ("$sym = new Object;");
        my ($k, $old_k, $v);
        foreach $k (keys %$elem) {
            $k = quotemeta($old_k=$k);
            my $newsym = (($k =~ /^[a-z_]\w+$/i) ? "$sym.$k" : 
                  "$sym\['$k']");
            push(@list, __jsdump($newsym, $elem->{$old_k}, $dict, $undef));
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
  B<or>
  use Data::JavaScript {UNDEF=>0};
  
  @code = jsdump('my_array', $array_ref, 0);
  $code = jsdump('my_object', $hash_ref);
  $code = hjsdump('my_stuff', $array_ref B<or> $hash_ref);

=head1 DESCRIPTION

This module is aimed mainly for CGI programming, when a perl script
generates a page with client side JavaScript code that needs access to
structures created on the server.

It works by creating one line of JavaScript code per datum. Therefore,
structures cannot be created anonymously and needed to be assigned to
variables. This enables dumping big structures.

You may define a default to be substitued in dumping of undef values
at compile time by supplying the default value in anonymous hash like so

  use Data::JavaScript {UNDEF=>'null'};

=over

=item jsdump('name', \$reference, [$undef]);

The first argument is required, the name of JavaScript object to create.

The second argument is required, a hashref or arrayref. Structures can be
nested, circular referrencing is supported EXPERIMENTALLY only.

The third argument is optional, a scalar whose value is to be used when
dumping a structure. If unspecified undef is output as C<''>. Other useful
values might be C<0>, C<q(null);> and C<q(NaN);>

When called in array context, the functions return an array of code
lines. When called in scalar context, it returns one chunk of lines
delimited by line fields.

=item hjsdump('name', \$reference, [$undef]);

hjsdump is identical jsdump except that it add HTML tags to embed the
script inside an HTML page.

=back

=head1 AUTHOR

Maintained by Jerrad Pierce<jpierce@cpan.org>

Ariel Brosh, schop@cpan.org. Inspired by WDDX.pm JavaScript support.

=head1 CREDITS 

Garick Hamlin B<ghamlin@typhoon.lightning.net>, fixing of quoting bug.

=head1 SEE ALSO

perl(1), L<WDDX>.

=cut
