#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);

my $bibdir = shift @ARGV;

my %booktable;

while (<ARGV>) {
  chomp;
  my ($canon_code, $full_name, $b21_code, $alt_codes_list) = split /\t/;
  $alt_codes_list //= '';
  my @alt_codes = split m{ / }, $alt_codes_list;
  my %record = (
    canon_code => $canon_code,
    full_name => $full_name,
    b21_code => $b21_code,
  );
  $booktable{$canon_code} = \%record;
  $booktable{$_} = \%record for @alt_codes;
  last if eof;
}

while (<STDIN>) {
  chomp;
  my @qs = split /;\s*/;
  for my $q (@qs) {
    my $text = '';
    my @spans = process_q($q);
    my $fspan = $spans[0];
    my $book = $fspan->{book};
    my $link = "https://www.obohu.cz/bible/index.php?lang=cz&styl=BKR&k=$book->{canon_code}&kap=$fspan->{start_chap}&v=$fspan->{start_verse}&kv=$fspan->{start_verse}#v$fspan->{start_verse}";
    my $fn = "$bibdir/$book->{b21_code}.html";
    my $book_html;
    {
      local (@ARGV, $/) = $fn;
      $book_html = <ARGV>;
    }
    for my $span (@spans) {
      my $start_chap = $span->{start_chap};
      my $start_verse = $span->{start_verse};
      my $end_chap = $span->{end_chap};
      my $end_verse = $span->{end_verse};
      my ($span_html) = $book_html =~ m!(<span [^>]*\bid="\w+/$start_chap/$start_verse".*<span [^>]*\bid="\w+/$end_chap/$end_verse".*?</span>)!;
      $span_html =~ s{<a [^>]*>[^<]*</a>}{}g;
      $text = "$text $span_html";
    }
    my ($raw_book, $spanlistcode) = split /\s+/, $q, 2;
    print "$book->{full_name} $spanlistcode\n";
    print "$text\n-----\n";
  }
}

sub process_q {
  my ($q) = @_;
  my ($raw_book, $spanlistcode) = $q =~ /(\S+)\s+(.*)/; #(\d+),\s*(\d+)\s*(.*)/;
  die "inexpected quotation: $q" if not $raw_book;
  my $book = $booktable{$raw_book};
  die "Unknown book $book" if not $book;
  my @spancodes = split /\s*\.\s*/, $spanlistcode;
  my @spans;
  my $recent_chap;
  for my $spancode (@spancodes) {
    my $verses_code;
    my $chap;
    if ($spancode =~ /^\s*(\d+)\s*,\s*(.*)/) {
      $chap = $1;
      $recent_chap = $chap;
      $verses_code = $2;
    }
    elsif (not defined $recent_chap) {
      die "unexpected biblical quotation $q";
    }
    else {
      $chap = $recent_chap;
      $verses_code = $spancode;
    }
    if ($verses_code =~ /(\d+)\s*-\s*(\d+)\s*,\s*(\d+)/) {
      $recent_chap = $2;
      push @spans, { book => $book, start_chap => $chap, start_verse => $1, end_chap => $recent_chap, end_verse => $3 };
    }
    elsif ($verses_code =~ /(\d+)\s*-\s*(\d+)/) {
      push @spans, { book => $book, start_chap => $chap, start_verse => $1, end_chap => $chap, end_verse => $2 };
    }
    elsif ($verses_code =~ /(\d+)nn/) {
      push @spans, { book => $book, start_chap => $chap, start_verse => $1, end_chap => $chap, end_verse => $1 + 2 };
    }
    elsif ($verses_code =~ /(\d+)n/) {
      push @spans, { book => $book, start_chap => $chap, start_verse => $1, end_chap => $chap, end_verse => $1 + 1 };
    }
    elsif ($verses_code =~ /(\d+)/) {
      push @spans, { book => $book, start_chap => $chap, start_verse => $1, end_chap => $chap, end_verse => $1 };
    }
    else {
      die "unexpected biblical quotation $q";
    }
  }
  return @spans;
}
