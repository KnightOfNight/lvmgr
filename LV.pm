

package LV;


use strict;
use warnings;

use File::Temp;

my $VOL_GROUP;
my $ERROR;


sub new () {
	my $class = $_[0];
	my $vol_group = $_[1];

	$ERROR = "";

	$VOL_GROUP = $vol_group;

	die("LV: fatal error, volume group not set\n") if ( ! defined($VOL_GROUP) );

	my $self = {};
	bless ($self, $class);
	return($self);
}


sub vol_list () {
    my $self = $_[0];

	my $stdout = mktemp("/tmp/lvs.stdout.XXXXXXXXXX");
	my $stderr = mktemp("/tmp/lvs.stderr.XXXXXXXXXX");
	my $cmd = "/sbin/lvs --units g --separator , --noheadings > $stdout 2> $stderr";

	my $retval = system($cmd);

	my $errlines = $self->file2str($stderr);

	if ( $retval ) {
		die( "LV: fatal error, system($cmd) failed\n" . $errlines );
	}

	if ( -s $stderr ) {
		die( "LV: fatal error, error reading output of 'lvs'\n" . $errlines );
	}

	if ( ! -s $stdout ) {
		die( "LV: fatal error, no output from 'lvs'\n" );
	}

	my @lines = $self->file2array($stdout);

	unlink($stdout);
	unlink($stderr);

	return( @lines );
}


sub vol_search () {
    my $self = $_[0];
    my $vol_name = $_[1];

	my @list = $self->vol_list();

	return( grep( /$vol_name/, @list ) );
}


sub vol_add () {
    my $self = $_[0];
    my $uuid = $_[1];
    my $size = $_[2];

	my $name = "lv_" . $uuid;

	my $stdout = mktemp("/tmp/lvcreate.stdout.XXXXXXXXXX");
	my $stderr = mktemp("/tmp/lvcreate.stderr.XXXXXXXXXX");
	my $cmd = "/sbin/lvcreate --name $name --size ${size}G $VOL_GROUP > $stdout 2> $stderr";

	my $retval = system($cmd);

	my $errlines = $self->file2str($stderr);

	my $ret = 1;

	if ( $retval ) {
		$ERROR = "system($cmd) failed\n" . $errlines;
		$ret = 0;
	}

	if ( -s $stderr ) {
		$ERROR = "error reading output of 'lvs'\n" . $errlines;
		$ret = 0;
	}

	unlink($stdout);
	unlink($stderr);

	return($ret);
}


sub vol_remove () {
    my $self = $_[0];
    my $uuid = $_[1];

	my $name = "lv_" . $uuid;

	my $stdout = mktemp("/tmp/lvremove.stdout.XXXXXXXXXX");
	my $stderr = mktemp("/tmp/lvremove.stderr.XXXXXXXXXX");
	my $cmd = "/sbin/lvremove --force /dev/mapper/$VOL_GROUP/$name > $stdout 2> $stderr";

	my $retval = system($cmd);

	my $errlines = $self->file2str($stderr);

	my $ret = 1;

	if ( $retval ) {
		$ERROR = "system($cmd) failed\n" . $errlines;
		$ret = 0;
	}

	if ( -s $stderr ) {
		$ERROR = "error reading output of 'lvs'\n" . $errlines;
		$ret = 0;
	}

	unlink($stdout);
	unlink($stderr);

	return($ret);
}


sub vol_size () {
    my $self = $_[0];
    my $uuid = $_[1];

	my @matches = $self->vol_search($uuid);

	my $match = $matches[0];

	my @fields = split(",", $match);

	my $size = $fields[3];

	return($size);
}


sub vol_shared_netatalk () {
    my $self = $_[0];
    my $uuid = $_[1];

	return( ! system("grep -q $uuid /etc/netatalk/AppleVolumes.default") );
}


sub vol_mounted() {
    my $self = $_[0];
    my $uuid = $_[1];

	return( ! system("mount | grep -q $uuid") );
}


sub vol_fstab_entry () {
    my $self = $_[0];
    my $uuid = $_[1];

	return( ! system("grep -q $uuid /etc/fstab")  );
}


sub file2array () {
    my $self = $_[0];
    my $file = $_[1];

	my $file_h;
	my @lines;
	my $lines;

	open($file_h, "<", $file) || die("LV: fatal error, unable to open file '$file'");
	@lines = <$file_h>;
	close($file_h);

	chomp(@lines);

	@lines = grep( s/^\s*//g, @lines );
	@lines = grep( s/\s*$//g, @lines );

	return(@lines);
}


sub file2str () {
    my $self = $_[0];
    my $file = $_[1];

	my @lines = $self->file2array($file);

	my $lines;

	map {
		$lines .= $_ . "\n";
	} @lines;

	return($lines);
}


sub error () {
	my $self = $_[0];

	my $CURR_ERROR = $ERROR;

	if ( ! $CURR_ERROR ) {
		return("");
	}

	$ERROR = "";

	return("LV: " . $CURR_ERROR);
}


1;


