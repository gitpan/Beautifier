#!/usr/bin/perl -w -I.

use strict;
use Beautifier;

### This example reads the contents of a file (specified on the command line as first argument)
### and prints the beautified code to STDOUT. Try this on the command line: example.pl example.pl

if (@ARGV == 1)
{
  undef $/; ### To read file all in one big slurp
  if (open (FH, $ARGV[0]))
  {
    my $fileContent = <FH>;
    close (FH);
    my $beautify = new Beautifier;
    print $beautify->Beautify(
                              { 'Indent' => "  ", ### use "\t" for a tab
                                'CurlyBraceOnNewLine' => 'yes', ### either yes or no
                                'SpaceBeforeParenthesisOpen' => 'yes',
                              },
                              $fileContent
                             );
  }
  else
  {
    die "Could not open $ARGV[0] for reading: $!\n";
  }
  $/ = "\n"; ### Back to default
}
else
{
  print "Usage: $0 program.pl\n";
}
                      