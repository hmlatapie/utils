#!/usr/bin/perl
use Data::Dumper;
use Carp;
use Time::HiRes qw(time sleep);
use Getopt::Long;

$usage = <<EOS;
$0 cmd options
	valid commands:
		selfinstall
		create filename|dir
			creates installer
			filename -> filename.pl
			--secure
		encrypt filename
			encrypts filename -> filename.enc
		decrypt filename
			decrypts filename.enc -> filename
		copysource dir
			copies all source code from dir 
		get repo filename
			filename does not include .tgz.enc.pl
		install repo filename
		put repo filename msg
			without .tgz.enc.pl
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

	if(-d $filename)
	{
		print "processing directory: $filename\n";
		$dir = $filename;
		$filename = $dir . '.tgz';
		`tar -czvf $filename $dir`;
	}
	elsif(-e $filename)
	{
		print "processing filename: $filename\n";
	}
	else
	{
		confess $usage;
	}

	$orig_filename = $filename;

	if($options{secure})
	{
		`$0 encrypt $filename`;
		$filename = $filename . '.enc';
	}

	`cat $0 $filename > $filename\.pl`; 
	`chmod +x $filename\.pl`;

	`rm $filename`
		if $options{secure};

	if($dir)
	{
		`rm $orig_filename`;
	}
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
elsif($command eq 'copysource')
{
	$dir = shift;
	confess $usage
		if !$dir;

	$cmd =<<EOS;
mkdir -p sourcecode && \\
cd $dir && \\
find . -iname '*.py' |xargs -d'\n' -n1 -Iasdf python -m py_compile asdf && \\
find . -iname '*.py' |xargs -d'\n' -n1 -Iasdf cp --parents asdf ../sourcecode/ && \\
find . -iname '*.pl' |xargs -d'\n' -n1 -Iasdf cp --parents asdf ../sourcecode/ && \\ 
find . -iname '*.json' |xargs -d'\n' -n1 -Iasdf cp --parents asdf ../sourcecode/ && \\ 
find . -iname '*.html' |xargs -d'\n' -n1 -Iasdf cp --parents asdf ../sourcecode/ 
EOS
	`$cmd`;
	`tar -czvf $dir\_sourcecode.tgz sourcecode/`;
}
elsif($command eq 'get')
{
	$repo = shift;
	$filename = shift;
	confess $usage
		if !$repo || !$filename;		
	$fullfilename = "$filename\.tgz\.enc\.pl";
	`rm $fullfilename`
		if -e $fullfilename;
	print `github.pl get $repo $fullfilename`;
	`chmod +x $fullfilename`;
}
elsif($command eq 'install')
{
	$repo = shift;
	$filename = shift;
	$fullfilename = "$filename\.tgz\.enc\.pl";
	confess $usage
		if !$repo || !$filename;		
	`pkgr.pl get $repo $filename`;
	`./$fullfilename selfinstall`;
	`rm $fullfilename`;
}
elsif($command = 'put')
{
	$repo = shift;
	$filename = shift;
	$msg = shift;
	$fullfilename = "$filename\.tgz\.enc\.pl";

	confess $usage
		if !$repo || !$filename || !$msg;		

	print "file: $fullfilename doesn't exist\n"
		if ! -e $fullfilename;

	$repobasedir = "$ENV{HOME}/dev/$repo";
	print "no destination repo directory for: $repobasedir\n"
		if ! $repobasedir;

	`cp $fullfilename $repobasedir`;
  	`cd $repobasedir && git commit -a -m \"$msg\"`;
	`cd $repobasedir && git push`;
}
else
{
	confess $usage;
}

__DATA__
