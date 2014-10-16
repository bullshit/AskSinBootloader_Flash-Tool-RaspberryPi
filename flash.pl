#!/usr/bin/perl

use Cwd 'abs_path';
use File::Basename;

##############
# Flash-Tool #
##############

sub explainUsageAndExit(@);
sub checkHex ($);

###############################################################################

if(int(@ARGV) < 1) {
	explainUsageAndExit();
}

my $hexFile      = $ARGV[0];
my $hmType       = $ARGV[1];
my $hmID         = $ARGV[2];
my $serialNr     = $ARGV[3];

if ( !(-e "$hexFile") ) {
    explainUsageAndExit("Can't access the given hexfile.");
}

##########################
# Set the default values #
##########################
my $defHmId1        = 'AB';
my $defHmId2        = 'CD';
my $defHmId3        = 'EF';
my $hmId1           = '';
my $hmId2           = '';
my $hmId3           = '';
my $defHmType1         = '12';
my $defHmType2         = '34';
my $defSerialNumber = 'HB0Default';
my $curPath         = $dirname = dirname(abs_path($0));
my ($fileBasename, $filePath, $fileExt) = fileparse($hexFile, '\..*');

##########################
# convert hexfile to bin #
##########################
`$curPath/bin/hex2bin -c $hexFile`;

if (defined($hmType) && defined($hmID) && defined($serialNr)) {
	###########################
	# Check the valid HM-Type #
	###########################
	($hmType1,$hmType2) = split(/:/, $hmType);
	if (!checkHex($hmType1) || !checkHex($hmType2)) {
		explainUsageAndExit ("The entered Type $hmType is invalid. Format: XX:XX. Each X must be 0-9 or A-F.");
	}

	#########################
	# Check the valid HM-ID #
	#########################
	($hmId1, $hmId2, $hmId3) = split(/:/, $hmID);

	if (!checkHex($hmId1) || !checkHex($hmId2) || !checkHex($hmId3)) {
		explainUsageAndExit ("The entered HM-ID $hmID is invalid. Format: XX:XX:XX. Each X must be 0-9 or A-F.");
	} else {
		$hmID = $hmId1 . $hmId2 . $hmId3;
	}

	#################################
	# Check the valid serial number #
	#################################
	if ( !($serialNr =~ /^[0-9a-zA-Z]{10}$/) ) {;
		explainUsageAndExit ("The serial number must contains 10 characters 0-9 or A-Z.");
	}

	##########################################################
	# Write user defined HM-ID and serial number to bin-file #
	##########################################################
	my $sedParams = '"s/\(\x' . $defHmType1 . '\x' . $defHmType2 . '\)\(' . $defSerialNumber . '\)\(\x' .$defHmId1 . '\x' .$defHmId2 . '\x' .$defHmId3 . '\)/\x' . $hmType1. '\x' . $hmType2. '' . $serialNr . '\x' . $hmId1 . '\x' . $hmId2 . '\x' . $hmId3 . '/" ' . $curPath . '/' . $fileBasename . '.bin > ' . $curPath . '/' . $fileBasename . '.tmp';
	`sed -b -e $sedParams`;

	unlink "$curPath/$fileBasename.bin";
	rename "$curPath/$fileBasename.tmp", "$fileBasename.bin";
} 
else {
	print 'Use default serialNumber hmId and hmType';
}


####################
# Write Bootloader #
####################

print "\nTest  Bootloader connection\n";
$result = `$curPath/bin/avrdude -C$curPath/bin/avrdude.conf -p atmega328p -P gpio -c gpio 2>&1`;
print $result;

if (index($result, 'initialization failed') != -1) {
	print "Failed to connect to bootloader!\n";
	exit(1);
}

print "\nWrite Bootloader\n";
$result = `$curPath/bin/avrdude -C$curPath/bin/avrdude.conf -p atmega328p -P gpio -c gpio -e -Uflash:w:$fileBasename.bin:r -Ulock:w:0x2F:m`;
print $result;



##########################
# Write out param errors #
##########################
sub explainUsageAndExit(@) {
	my ($txt) = @_;

	print "\n";
	if (defined($txt)) {
		print "$txt\n"
	}

	print "Usage: flash.pl <hexfile> [<hmtype> <HM-ID> <Serial>]\n";
	exit (0);
}


#######################################
# Check a variable if is a hex number #
#######################################
sub checkHex ($) {
	my ($val) = @_;
	my $retVal = 0;
	
	if ($val =~ /^[0-9a-fA-F]{2}$/) {;
		$retVal = 1;
	}

	return $retVal;
}
