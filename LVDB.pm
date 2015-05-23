

package LVDB;


use strict;
use warnings;
use Digest::MD5 qw/md5_hex/;


my $LVDB_FILE = "/usr/local/etc/lv-list";
my $ERROR;


sub new () {
	my $class = $_[0];

	$ERROR = "";

	if ( ! -r $LVDB_FILE ) {
		printf("LVDB: warning, database '$LVDB_FILE' is not readable\n");
	}

	if ( ! -w $LVDB_FILE ) {
		printf("LVDB: warning, database '$LVDB_FILE' is not writable\n");
	}

	my $self = {};
	bless ($self, $class);
	return($self);
}


sub dbread () {
	my $self = $_[0];

	my $dbfh;
	my @dblines;

	open($dbfh, "< $LVDB_FILE") || die("LVDB: fatal error, unable to open LV database $LVDB_FILE for read\n");
	@dblines = <$dbfh>;
	close($dbfh);

	chomp(@dblines);

	return(@dblines);
}


sub dbwrite () {
	my $self = $_[0];
	my @newlines = @_;

	shift(@newlines);

	my $dbfh;

	if ( ! open($dbfh, "> $LVDB_FILE") ) {
		$ERROR = "unable to open LV database $LVDB_FILE for write";
		return(0);
	}

	map {
		printf $dbfh ("%s\n", $_);
	} @newlines;

	close($dbfh);

	return(1);
}


sub valid_uuid () {
	my $self = $_[0];
	my $uuid = $_[1];

	if ( scalar( $uuid =~ /^[\da-f]{32}$/ ) ) {
		return(1);
	} else {
		return(0);
	}
}


sub desc2uuid () {
	my $self = $_[0];
	my $desc = $_[1];

	return( md5_hex($desc . "\n") );
}


sub vol_exists () {
	my $self = $_[0];
	my $uuid = $_[1];

	if ( ! $self->valid_uuid($uuid) ) {
		return(0);
	}

	return( grep(/^$uuid /, $self->dbread() ) );
}


sub vol_add () {
	my $self = $_[0];

	my $uuid = $_[1];
	my $desc = $_[2];

	if ( ! $self->valid_uuid($uuid) ) {
		return(0);
	}

	if ( $self->vol_exists($uuid) ) {
		$ERROR = "unable to add UUID $uuid - already present in database";
		return(0);
	}

	if ( $uuid ne $self->desc2uuid($desc) ) {
		$ERROR = "unable to add record (UUID '$uuid', description '$desc') - MD5 does not match";
		return(0);
	}

	my @dblines = $self->dbread();

	push(@dblines, "$uuid $desc");

	return( $self->dbwrite(@dblines) );
}


sub vol_remove () {
	my $self = $_[0];
	my $uuid = $_[1];

	if ( ! $self->valid_uuid($uuid) ) {
		return(0);
	}

	my @newlines = grep( !/^$uuid /, $self->dbread() );

	return( $self->dbwrite(@newlines) );
}


sub vol_desc () {
	my $self = $_[0];
	my $uuid = $_[1];

	if ( ! $self->valid_uuid($uuid) ) {
		return("");
	}

	my @match = grep(/^$uuid /, $self->dbread() );

	my $match = "";

	if ( @match ) {
		$match = $match[0];
		$match =~ s/^$uuid //;
	}

	return($match)
}


sub error () {
	my $self = $_[0];

	my $CURR_ERROR = $ERROR;

	if ( ! $CURR_ERROR ) {
		return("");
	}

	$ERROR = "";

	return("LVDB: " . $CURR_ERROR);
}


1;


