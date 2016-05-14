#!/usr/bin/perl
use Data::Dumper;
use Carp;
use Time::HiRes qw(time sleep);
use Getopt::Long;
use lib "$ENV{HGDIR}/bb/misc";
use misc;
use BIST;
BIST();

$usage = <<EOS;
$0 cmd options
	valid commands:
		get repo file
	options:
EOS

GetOptions(
	'stringparam=s' => \$options{stringparam},
	'booleanparam' => \$options{booleanparam}
	);

confess $usage
	if !@ARGV;

$command = shift;

if($command eq 'get')
{
	$repo = shift;
	$file = shift;
	confess $usage
		if !$repo || !$file;
	$user = 'hmlatapie';
	$cmd = <<EOS;
wget https://raw.githubusercontent.com/$user/$repo/master/$file
EOS
	print `$cmd`;
}
else
{
	confess $usage;
}

