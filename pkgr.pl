#!/usr/bin/perl
use Data::Dumper;
use Carp;
use Time::HiRes qw(time sleep);
use Getopt::Long;

$usage = <<EOS;
$0 cmd options
	valid commands:
		selfinstall
		create filename
			creates installer
			filename -> filename.pl
			--secure
		encrypt filename
			encrypts filename -> filename.enc
		decrypt filename
			decrypts filename.enc -> filename
	options:
		--secure
			works with encrypted files
EOS

GetOptions(
	'stringparam=s' => \$options{stringparam},
	'booleanparam' => \$options{booleanparam},
	'secure' => \$options{secure},
	);

confess $usage
	if !@ARGV;

$command = shift;

if($command eq 'encrypt')
{
	$filename = shift;
	confess $usage
		if !$filename;
	`openssl enc -aes-256-cbc -salt -in $filename -out $filename\.enc`;
}
elsif($command eq 'decrypt')
{
	$filename = shift;
	confess $usage
		if !$filename;
	$filename =~ s/\.enc//;
	`openssl enc -d -aes-256-cbc -in $filename\.enc -out $filename`;
}
elsif($command eq 'create')
{
	$filename = shift;
	confess $usage
		if !$filename;

	if($options{secure})
	{
		`$0 encrypt $filename`;
		$filename = $filename . '.enc';
	}

	`cat $0 $filename > $filename\.pl`; 
	`chmod +x $filename\.pl`;

	`rm $filename`
		if $options{secure};
}
elsif($command eq 'selfinstall')
{
	$secure = 1
		if $0 =~ /.enc.pl$/;
	$filename = 'temp.out';
	$filename = $filename . '.enc'
		if $secure;
	binmode DATA;
	open $f, ">$filename";
	print $f $_ 
		while <DATA>;
	if($secure)
	{
		`$0 decrypt $filename`; 
		$filename =~ s/.enc$//;
	}
	`tar -xzf $filename`;
	`rm $filename`;
}
else
{
	confess $usage;
}

__DATA__
