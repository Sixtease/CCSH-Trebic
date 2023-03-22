#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);
use Text::Unidecode qw(unidecode);
use File::Basename qw(basename);
use Encode qw(decode_utf8);

while (<>) {
  last if /<body/;
}

my $header = <>;
$header =~ s/<.*//s;
my ($date, $texts) = split /\t/, $header;

if ($date =~ / /) {
  warn "date has appendix: $ARGV $date";
  $date =~ s/ .*//;
}

(my $title = basename decode_utf8 $ARGV) =~ s/Kázo //;
$title =~ s/\.html//;
$title = ucfirst $title;

(my $basetitle = lc(unidecode $title)) =~ s/\s+/-/g;

say 'AUTHOR: Jan Oldřich Krůza';
say "TITLE: $title";
say "BASENAME: $date-$basetitle";
say "DATE: ${date}T14:00";
say "TEXTS: $texts";
say "CATEGORY: Kázání";
say '-----';
print 'BODY:';

while (<>) {
  last if m{</p>};
}

#my $consecutive_newlines = 0;
#my $in_p = 0;

while (<>) {
  last if /<font size/;
  #$consecutive_newlines++ if /<p\b/;
  print "\n" if /<p\b/;
  s/<[^>]*>//g;

  if (/\w/) {
    #if ($consecutive_newlines > 0) {
    #  if ($in_p) {
    #    say '</p>';
    #  }
    #  say '<p>';
    #  $in_p = 1;
    #}
    #$consecutive_newlines = 0;
    print;
  }
}

#if ($in_p) {
#  say '</p>';
#}
