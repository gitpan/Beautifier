package Beautifier;

use strict;
use warnings;
our $VERSION = '0.02';

sub new()
{
  my $self = shift;
  return bless {}, $self;
}

sub Beautify($$)
{
  ### First element of @_ is a reference to the element that called this subroutine
  my $self = shift;
  ### Second is a reference to a hash with options
  my $options = shift;
  ### Third is a string that contains the code to beautify
  my $fileContent = shift;
  ### Modify the value of $indent to your preference (use "\t" for a tab)
  my $indent = "  ";
  if ($$options{'indent'})
  {
    $indent = $$options{'indent'};
  }

  ### Random string used for replacing comments and string values temporarily. You don't have to modify this.
  my $randomString = 'abcdefghijklmnopqrstuvwxyz';
  
  ### step 0: save all stuff between "" or '' or `` or q{} or qq{} or qx{} or qw{} or m{} or qr{} or s{}{} or tr{}{} or after # or <<EOF
  my $counter = 0;
  my @quotedStrings;
  ### Here documents, Multi-line strings (like in my $var = <<EOF;)
  while ($fileContent =~ m/(\<\<([\"\']?)(.*?)\2[\;\,])/g)
  {
    my $opener = $1;
    my $terminator = $3;
    $fileContent =~ s/(\Q$opener\E.*?\n\Q$terminator\E\n)/$randomString$counter;/s;
    $quotedStrings[$counter] = $1;
    $counter++;
  }
  ### Comment (like in statement; #comment)
  while ($fileContent =~ m/(\#.*)$/gm)
  {
    my $quotedString = $1;
    $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
    $quotedStrings[$counter] = $quotedString;
    $counter++;
  }
  ### Strings (like in my $var = "blah";)
  while ($fileContent =~ m/((\"|\'\`).*?[^\\]\2)/g)
  {
    my $quotedString = $1;
    $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
    $quotedStrings[$counter] = $quotedString;
    $counter++;
  }
  ### Strings (like in my $var = q#blah#;)
  while ($fileContent =~ m/((?:q|qq|qx|qw|m|qr)([^a-zA-Z0-9_ \t\n]).*?[^\\]\2)/g)
  {
    my $quotedString = $1;
    $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
    $quotedStrings[$counter] = $quotedString;
    $counter++;
  }
  ### Strings (like in my $var = q{blah};)
  for my $pairingDelimiters ('()', '{}', '[]')
  {
    my $open = substr($pairingDelimiters, 0, 1);
    my $close = substr($pairingDelimiters, 1, 1);
    while ($fileContent =~ m/((?:q|qq|qx|qw|m|qr)\Q$open\E.*?[^\\]\Q$close\E)/g)
    {
      my $quotedString = $1;
      $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
      $quotedStrings[$counter] = $quotedString;
      $counter++;
    }
  }
  ### Strings (like in my $var = s#blah#foo#;)
  while ($fileContent =~ m/((?:s|tr)([^a-zA-Z0-9_ \t\n]).*?[^\\]\2.*?[^\\]\2)/g)
  {
    my $quotedString = $1;
    $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
    $quotedStrings[$counter] = $quotedString;
    $counter++;
  }
  ### Strings (like in my $var = s{blah}{foo};)
  for my $pairingDelimiters ('()', '{}', '[]')
  {
    my $open = substr($pairingDelimiters, 0, 1);
    my $close = substr($pairingDelimiters, 1, 1);
    while ($fileContent =~ m/((?:s|tr)\Q$open\E.*?[^\\]\Q$close\E\Q$open\E.*?[^\\]\Q$close\E)/g)
    {
      my $quotedString = $1;
      $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
      $quotedStrings[$counter] = $quotedString;
      $counter++;
    }
  }
  ### Regexps (like in $var =~ /blah/)
  while ($fileContent =~ m/((?:\=|\!)\~ \/.*?\/)/g)
  {
    my $quotedString = $1;
    $fileContent =~ s/\Q$quotedString\E/$randomString$counter;/;
    $quotedStrings[$counter] = $quotedString;
    $counter++;
  }

  ### Step 1 remove leading & trailing whitespace on all lines
  $fileContent =~ s/[ \t]*\n[ \t]*/\n/g;

  ### step 2: remove all but one whitespace between 2 words
  $fileContent =~ s/[ \t]+/ /g;

  ### step 3: move opening curly to new line and append newline
  $fileContent =~ s/(\)|else|sub \w+)\s*\{\s*/$1\n\{\n/g; ### Standard else {
  $fileContent =~ s/(\)|else|sub \w+)\s*\{\s*($randomString[0-9]+;)\s*/$1\n\{\n$2\n/g; ### with comment # after {
  $fileContent =~ s/(\)|else|sub \w+)\s*($randomString[0-9]+;)\s*\{\s*/$1$2\n\{\n/g; ### with comment # before {

  ### step 4: spacing around () 
  my $operators = '(\*\*\=|\+\=|\*\=|\&\=|\<\<\=|\&\&\=|\-\=|\/\=|\|\=|\>\>\=|\|\|\=|\.\=|\%\=|\^\=|x\=|\=\~|\!\~|\<\=|\>\=|\=\=|\!\=|\<\=\>|\&\&|\|\||\.\.|\=)'; ###\<|\>|\+|\-|\*|\/|\%|\*\*|\.|\,)';
  $fileContent =~ s/ *(\(|\)) */$1/g;
  $fileContent =~ s/ *($operators) */ $1 /g;
  $fileContent =~ s/(if|while|for|foreach)\(/$1 (/g; ### add after ifs and stuff

  ### step 5: add indenting
  my $openCurlies = 0;
  my @fileContent = split("\n", $fileContent);
  $fileContent = '';
  foreach my $line (@fileContent)
  { if ($line =~ m/^}/)
    {
      $openCurlies--;
    }
    $fileContent .= $indent x $openCurlies;
    $fileContent .= $line . "\n";
    if ($line =~ m/^{/)
    {
      $openCurlies++;
    }
  }
  if ($openCurlies != 0)
  {
    warn "Uh-oh, i messed up with the curlies. \$openCurlies = $openCurlies.\n";
  }

  ### step 1000: reverse step 0
  $fileContent =~ s/$randomString([0-9]+);/$quotedStrings[$1]/g;

  ### Return the beautified code
  return $fileContent;
}

1;

__END__

=head1 NAME

Beautifier - Perl extension for beautifying/styling/prettyprinting perl code.

=head1 SYNOPSIS

  use Beautifier;

  my $beautifier = new Beautifier;
  print $beautifier->Beautify(
                        {'indent' => "  "},
                        "$this = 'some perl code';\n";
                      );

=head1 DESCRIPTION

This module pretty prints/beautifies perl code.
This might come in handy when working on other people's code (don't you hate that?)
It uses my coding conventions, like placing the curly on the next line.
Feel free to change it to your style (which, if different from mine, is wrong)
Here is what code will look like afterf it's been crunched by Beautifier:

  if (($varName =~ m//) && (-f $fileName))
  {
    print "Hello, world!\n";
  }

WARNING: A working program might no longer work after Beautifier did her thing on it. (Beautifier is definitely female)

=head1 EXAMPLES

  #!/usr/bin/perl -w

  use strict;
  use Beautifier;


  undef $/; ### To read file all in one swoop
  open (FH, "test.pl") || die $!;
  my $fileContent = <FH>;
  close (FH);
  $/ = "\n"; ### Back to default

  my $beautify = new Beautifier;
  print $beautify->Beautify(
                            { 'indent' => "  ",
                            },
                            $fileContent
                           );

=head1 AUTHOR

Teun van Eijsden, E<lt>teun@chello.nlE<gt>

=head1 SEE ALSO

L<perl>.

=cut

