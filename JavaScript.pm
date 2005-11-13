package Data::JavaScript;
require 5;
use vars qw(@EXPORT @EXPORT_OK @ISA %OPT $VERSION);
%OPT = (JS=>1.3);
$VERSION = 1.10;

use Exporter;
@EXPORT = qw(jsdump hjsdump);
@EXPORT_OK = '__quotemeta';
@ISA = qw(Exporter);

use strict;
require Encode unless $] < 5.007;

sub import{
  foreach( @_ ){
    if(ref($_) eq 'HASH'){
      foreach my $opt ( 'UNDEF', 'JS' ){
	if(exists($_->{$opt})){
	  $OPT{$opt} = $_->{$opt};
	}
      }
    }
  }
  $OPT{UNDEF} = exists($OPT{UNDEF}) || $OPT{JS} > 1.2 ? 'undefined' : q('');
  Data::JavaScript->export_to_level(1, grep {!ref($_)} @_);
}

#XXX version, ECMAscript even. Charset!
sub hjsdump {
    my @res = (qq(<script type="text/javascript" language="JavaScript$OPT{JS}" />),
	       '<!--', &jsdump(@_), '// -->', '</script>');
    wantarray ? @res : join("\n", @res, "");
}

sub jsdump {
    my $sym  = shift;
    return "var $sym;\n" unless (@_);
    my $elem  = shift;
    my $undef = shift;
    my %dict;
    my @res   = __jsdump($sym, $elem, \%dict, $undef);
    $res[0]   = "var " . $res[0];
    wantarray ? @res : join("\n", @res, "");
}

if( $] < 5.007 ){
    eval <<'EO5';
sub __quotemeta {
  local $_ = shift;

  s<([^ !\x23-\x26\x28-\x7E]+)>{sprintf(join('', '\x%02X' x length($1)), unpack'C*',$1)}ge;
#{sprintf '\x%0*v2X', '\x', $1}ge;
  return $_;
}
EO5
}
    else{
	eval<<'EO58';
sub __quotemeta {
  local $_ = shift;
  if( $OPT{JS} >= 1.3 && Encode::is_utf8($_) ){
      s<([\x{0080}-\x{fffd}]+)>{sprintf '\u%0*v4X', '\u', $1}ge;
  }
  
  use bytes;  
  s<((?:[^ !\x23-\x26\x28-\x7E]|(?:\\(?!u)))+)>{sprintf '\x%0*v2X', '\x', $1}ge;
  return $_;
}
EO58
}

sub __jsdump {
    my ($sym, $elem, $dict, $undef) = @_;

    unless (ref($elem)) {
      unless( defined($elem) ){
	return "$sym = @{[defined($undef) ? $undef : $OPT{UNDEF}]};";
      }

      #Translated from $Regexp::Common::RE{num}{real}
      if( $elem =~ /^[+-]?(?:(?=\d|\.)\d*(?:\.\d{0,})?)$/ ){
#                                                      (?:[eE][+-]?\d+)?
	  return qq($sym = "$elem";) if $elem =~ /^0\d+$/;
	  return "$sym = $elem;";
      }

      #Fall-back to quoted string
      return qq($sym = ") . __quotemeta($elem) . '";';
    }

    #Circular references
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
            $k = __quotemeta($old_k=$k);
            my $newsym = (($k =~ /^[a-z_]\w+$/i) ? "$sym.$k" : 
                  "$sym\['$k']");
            push(@list, __jsdump($newsym, $elem->{$old_k}, $dict, $undef));
        }
        return @list;
    }
}


1;
__END__

=head1 NAME

Data::JavaScript - Dump perl data structures into JavaScript code

=head1 SYNOPSIS

  use Data::JavaScript;                        # Use defaults
  
  @code =  jsdump('my_array',  $array_ref);    # Return array for formatting
  $code =  jsdump('my_object', $hash_ref);     # Return convenient string
  $html = hjsdump('my_stuff',  $reference);    # Convenience wrapper for jsdump

=head1 DESCRIPTION

This module is mainly inteded for CGI programming, when a perl script
generates a page with client side JavaScript code that needs access to
structures created on the server.

It works by creating one line of JavaScript code per datum. Therefore,
structures cannot be created anonymously and need to be assigned to
variables. However, this format enables dumping large structures.

The module can output code for different versions of JavaScript.
It currently supports 1.2 and 1.3 and you specify the version on the
C<use> line like so:

  use Data::JavaScript {JS=>1.3};              # The new default
  use Data::JavaScript {JS=>1.2};              # Old format

JavaScript 1.3 contains support for UTF-8 and a native C<undefined> datatype.
JavaScript 1.2 supports neither, and will default to an empty string C<''>
for undefined values. You may define your own default--for either version--at
compile time by supplying the default value on the C<use> line:

  use Data::JavaScript {JS=>1.2, UNDEF=>'null'};

Other useful values might be C<0>, C<null>, or C<NaN>.

=over

=item jsdump('name', \$reference, [$undef]);

The first argument is required, the name of JavaScript object to create.

The second argument is required, a hashref or arrayref.
Structures can be nested, circular referrencing is supported (experimentally).

The third argument is optional, a scalar whose value is to be used en lieu
of undefined values when dumping a structure.

When called in list context, the functions return a list of lines.
In scalar context, it returns a string.

=item hjsdump('name', \$reference, [$undef]);

hjsdump is identical to jsdump except that it wraps the content in script tags.

=item __quotemeta($str)

Not exported by default, this function escapes non-printable and Unicode
characters to promote playing nice with others.

=back

=head1 SEE ALSO

perl(1), L<WDDX>.

=head1 AUTHOR

Maintained by Jerrad Pierce <jpierce@cpan.org>

Created by Ariel Brosh <schop cpan.org>. Inspired by WDDX.pm JavaScript support.

=head1 HISTORY

Previously, the module eval'd any data it received that looked like a number;
read: real, hexadecimal, octal, or engineering notations. It now passes
non-decimal values through as strings. You will need to C<eval> on the client
or server side if you wish to use other notations as numbers.
=cut
