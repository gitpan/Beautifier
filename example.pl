#!/opt/Perl5.6.0/bin/perl -w -I.

use strict;
use Beautifier;

 
undef $/; ### To read file all at once
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
                      