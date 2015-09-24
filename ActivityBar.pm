package ActivityBar;
use strict;
use vars '$VERSION';
require 'sys/ioctl.ph'; # This is required for determining terminal width.

$VERSION	= '0.01';

# These are internal-only items...

my $winSize; # Holder for packed window dinensional information.

# Make sure we can open the TTY to read it.
my $openTTY = sub {
	return undef unless (defined &TIOCGWINSZ);
	my $tty;
	open($tty, "+</dev/tty") || return undef;
	return undef unless (ioctl($tty, &TIOCGWINSZ, $winSize=''));
	return $tty;
};

# Returns a truncated string, if a input is provided. Otherwise, it just returns the terminal width.
my $termWidth = sub {
	my $msg	= $_[0];
	return $msg if (!&$openTTY);
	my ($rows, $columns, $xPixels, $yPixels) = unpack('S4', $winSize);
	if ($msg) {
		my $blankLen	= ($columns - (length ($msg)));
		$msg		= substr ($msg, 0, ($columns-10)) . " -TRUNC ##" if ($blankLen < 0);
		$msg		=~ s/$/' ' x $blankLen /mge if ($blankLen > 0); # Fill the end of the line with whitespace.
		return $msg;
	}
	return $columns;
}; # END my $termWidth = sub ...

# -----------------------

=head1 NAME

ActivityBar - Easy to use text-based animation/status bar, to let you know things are still working.

=head1 SYNOPSIS

  use ActivityBar;

  ActivityBar::animate ("MESSAGE");

  $bar = ActivityBar::make ("MESSAGE");

  # Override default config values. Default values are shown...
  $object = ArtivityBar->new ( {
   step => 100,
   fwchar => '|',
   bwchar => '-'
   length => 15,
   showcount => 1,
   countdesc => 'Count:',
  } );

  $object::animate ("MESSAGE");

=head1 DESCRIPTION

Easy to use text-based animation/status bar, to let you know things are still working.
Can be called as a standalone tool, or used as an object.

=head1 AUTHORS

Jeremy Melanson <jmelanson[at]systemhalted[dot]com>

=head1 CONFIG
These are defaults, and can be changed if desired. A couple methods exist for changing them.

=cut

my %config	= (
	step		=> 100,		# Update profress bar every 100 iterations.
	fwchar		=> '|',		# Fills progress bar with this character.
	bwchar		=> '-',		# Retreat progress bar with this character.
	length		=> 15,		# Progress bar length to prepend on line.
	showcount	=> 1,		# Prepend the bar with a total count of iterations.
	countdesc	=> 'Count:',	# iteration count is prepended with this.
);

=head1 SUBROUTINES

=over 4

=item new [{config_options}]

Create a new ActivityBar object. Options may be specified in an anonymous hash or hashref.

=cut

sub new {
	my $self	= $_[0];
	my $cnf		= $_[1];
	return undef if (!$self->updateConf ($_[1]));
	return $self;
}

=item make MESSAGE

Accept a string as input, and output the string prepended with an incremental "animation" bar.

=cut

my ($flip, $count, $iter, $walk);
my $make = sub {
	my ($self, $msg, $cnf);
	$msg		=~ s/[\r\b\n]*/ /g; # Replace these with spaces. We'll add our own.
	$msg		=~ s/[\ \t]+$//g; # Remove any trailing whitespace.
	$self		= $_[0]	if ($_[0] eq "ActivityBar");
	if ($self) {	$msg = $_[1]; } else {$msg = $_[0]; }
	if (!$self) {	$cnf = updateConf ($_[1]) }
	else {			$cnf = $self->updateConf ($_[2]) }
	$walk++;
	$count++;
	unless ($walk == $config{step}) { return undef; };
	$walk		= 0;
	$iter++;
	my $output	= "";
	for (my $c=1; $c<=$config{length}; $c++) {
		if (!$flip) {	if ($c <= $iter) {	$output .= $config{fwchar}; } else { $output .= $config{bwchar}; } }
		else {		if ($c >= ($config{length} - $iter)) {	$output .= $config{bwchar}; } else { $output .= $config{fwchar}; } }
	}
	if ($iter == $config{length}) { # Flip back and forth between grow and shrink animation.
		$iter	= 0;
		if ($flip) {
			$flip	= 0;
		} else {
			$flip	= 1;
		}
	}
	$output		= $config{countdesc} . sprintf ("%-8s ", $count) . $output if ($config{showcount});
	$output		.= " " . $msg;
	return &$termWidth ($output);
}; # END my $make = sub ...

# Public subroutine for private $get
sub make {
	return &$make (@_);
}

=item animate MESSAGE

Accept a string as input, and print it prepended with an incremental "animation" bar.
Similar to 'make', except this only prints the output, rather than returning a string.

=cut

sub animate {
	print &$make (@_) . "\r\b";
}

=item updateConf [{config_options}]

Update configuration settings on-the-fly.

Valid settings are:

  step      (default 100)      Update progress bar every <step> iterations.
  fwchar    (default '|')      Fills progress bar with this character.
  bwchar    (default '-')      Retreat progress bar with this character.
  length    (default 15)       Progress bar length to prepend on line.
  showcount (default 1)        Toggle to prepend the bar with a total count of iterations.
  countdesc (default 'Count:') iteration count is prepended with this.

=cut

sub updateConf {
	my ($self, $cnf);
	$self		= $_[0]	if ($_[0] eq "ActivityBar");
	if ($self) { $cnf = ($_[1]); } else { $cnf = $_[0]; }
	if (ref ($cnf) != "HASH") {
		print STDERR "Configuration options must be passed as a hash reference.\n";
		return undef;
	}
	return 2 if (checkOpts ($cnf));
	return 1;

	sub checkOpts {
		my $cnf	= $_[0];
		# Options recognized as 'valid'..
		my %validOpts	= ( fwchar => 'integer', bwchar => 'integer', step => 'integer',
								length => 'integer', showcount => 'integer', countdesc => 'string',);
		my $output;
		foreach my $o (keys (%validOpts)) {
			$output .= "Invalid Option: \'" . $o . "\'\n" if (!$cnf->{$o});
			$output .= "Option: \'" . $o . "\' must be a(n) " . $validOpts{$o} . ".\n" if (checkType ($cnf->{$o}));
			return $output;
		}
		return $output;
	}
	sub checkType {
		my ($optVal, $validType)	= ($_[0], $_[1]);
		my $validOpts	= $_[2];
		if ($validType eq "integer") { return 1 if ($optVal =~ /^[0-9]+$/); }
		else { return undef; }
	}
} # END sub updateConf

=item getConf [OPTION]

Return a hash of the current configuration.
An individual option may also be requested instead. The hash will contain only what was requested.

=cut

sub getConf {
	my ($self, $setting);
	$self		= $_[0]	if ($_[0] eq "ActivityBar");
	# Optionally request a specific setting...
	if ($self) { $setting = ($_[1]); } else { $setting = $_[0]; }
	if ($setting) {
		my %out; %out = ($setting => $config{$setting}) if ($config{$setting});
		return %out;
	}
	return %config;
}

=item dumpConf

Dump a multiline string outlining the current configuration settings..

=cut

sub dumpConf {
	my %cnf	= getConf (@_);
	my $out;
	foreach my $c (keys (%cnf)) {
		$out .= $c . " => " . $cnf{$c} . "\n";
	}
#	return $out . "\r\b";
	return $out;
}

=head1 AUTHORS

Jeremy Melanson <zish@systemhalted.com>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License 3.0 (or higher, at your discretion).

=cut

1;
