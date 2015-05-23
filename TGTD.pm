

package TGTD;


use strict;
use warnings;
use Digest::MD5 qw/md5_hex/;


my $CONF_DIR;
my $VOL_GROUP;
my $ERROR;


sub new () {
	my $class = $_[0];
	my $conf_dir = $_[1];
	my $vol_group = $_[2];

	$ERROR = "";

	$CONF_DIR = $conf_dir;
	$VOL_GROUP = $vol_group;

	die("TGTD: fatal error, configuration directory not set\n") if ( ! defined($CONF_DIR) );
	die("TGTD: fatal error, volume group not set\n") if ( ! defined($VOL_GROUP) );

	my $self = {};
	bless ($self, $class);
	return($self);
}


sub cfg_add () {
	my $self = $_[0];
	my $uuid = $_[1];

	my $file = $CONF_DIR . "/" . $uuid . ".conf";

	my $name = "lv_" . $uuid;

	if ( -s $file ) {
		$ERROR = "unable to add configuration for UUID '$uuid', file already found\n";
		return(0);
	}

	my $file_h;

	open($file_h, ">", $file) || die("TGTD: fatal error, unable to open file '$file' for write");

	print $file_h <<EOENTRY;
<target iqn.2012-10.com.magrathea.private.deepthought:$name>
backing-store /dev/mapper/$VOL_GROUP-$name
lun 1
incominguser diskuser ehs25x9puov2r322t2z6poke980sz32b
</target>
EOENTRY

	close($file_h);

}


sub cfg_remove () {
	my $self = $_[0];
	my $uuid = $_[1];

	my $file = $CONF_DIR . "/" . $uuid . ".conf";

	if ( ! -s $file ) {
		$ERROR = "unable to remove configuration for UUID '$uuid', file not found\n";
		return(0);
	}

	unlink($file);

	return(1);
}


sub cfg_reload () {
	my $self = $_[0];

	system("/etc/init.d/tgtd reload");
}


sub error () {
	my $self = $_[0];

	my $CURR_ERROR = $ERROR;

	if ( ! $CURR_ERROR ) {
		return("");
	}

	$ERROR = "";

	return("TGTD: " . $CURR_ERROR);
}


1;


