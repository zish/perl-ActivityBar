#!/usr/bin/perl
use strict;
use ActivityBar;
my $maxIter = 100000;

my @words = (
  'I', 'like', 'that', 'one', 'can', 'see', 'if', 'their',
  'program', 'is', 'still', 'happily', 'performing', 'its',
  'silly', 'little', 'tasks', 'because', 'the', 'progress',
  'bar', 'shows', 'how', 'far', 'along', 'we', 'have',
  'are', 'what', 'about', 'you', 'spork', 'monkey', 'beer' );

for (1..$maxIter) {
   my @sort = sort {int(rand(3))-1} (@words);
   ActivityBar::animate (join (' ', @sort[0 .. int (rand ($#words))]));
}
