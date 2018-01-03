#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin $RealBin);
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname basename);

my ($valid,$inputfq1,$inputfq2,$outfq1,$outfq2);
GetOptions(
        "i:s" => \$valid,
        "1:s" => \$inputfq1,
        "2:s" => \$inputfq2,
        "3:s" => \$outfq1,
        "4:s" => \$outfq2,
        );

unless($valid && $inputfq1 && $inputfq2 && $outfq1 && $outfq2){
    &usage;
    exit;
}

$| = 1;
system("mkdir $$");

#open LIST,"awk \'gsub(\"\/[0-9]\$\",\"\",\$1){print \$1}\' $valid | sort -t \"_\" -k1,1 -k2n,2 -T $$ -S 2G | " or die "$!\n";
open LIST,"awk \'gsub(\"\/[0-9]\$\",\"\",\$1){print \$1}\' $valid | sort -t \"_\" -k1,1 -T $$ -S 2G | " or die "$!\n";
if( $inputfq1 =~ /\.gz$/ ){
    open FQA,"gzip -dc $inputfq1 | " or die "$!\n";
}else{
    open FQA,"$inputfq1" or die "$!\n";
}
if( $inputfq2 =~ /\.gz$/ ){
    open FQB,"gzip -dc $inputfq2 | " or die "$!\n";
}else{
    open FQB,"$inputfq2" or die "$!\n";
}

if( $outfq1 =~ /\.gz$/ ){
    open OUA,"| gzip > $outfq1" or die "$!\n";
}else{
    open OUA,"| gzip > $outfq1.gz" or die "$!\n";
}
if( $outfq2 =~ /\.gz$/ ){
    open OUB,"| gzip > $outfq2" or die "$!\n";
}else{
    open OUB,"| gzip > $outfq2.gz" or die "$!\n";
}

my %tags = ();
my $flag = 0;
while(1){
    my $pre = "";
    while(<LIST>){
        chomp;
        my $id = "";
        if( /^(\w+C\d+)/ ){
            $id = $1;
        }
        if( $id ne $pre && $pre ne "" ){
            $pre = $_;
            $flag = 0;
            last;
        }else{
            $pre = $id;
            $flag = 1;
        }
        $tags{$_} = 1;
    }
    while(<FQA>){
        my $name1 = $_;
        my $id = (split /\s+|\//,$_)[0];
        $id =~ s/^\@//;
        my $seq1 = <FQA>;
        my $strand1 = <FQA>;
        my $qual1 = <FQA>;

        my $name2 = <FQB>;
        my $seq2 = <FQB>;
        my $strand2 = <FQB>;
        my $qual2 = <FQB>;
        next unless( delete $tags{$id} );
        print OUA "$name1$seq1$strand1$qual1";
        print OUB "$name2$seq2$strand2$qual2";
        last if( keys %tags == 0 );
    }
    last if( 1 == $flag );
    $tags{$pre} = 1;
}
close LIST;
close FQA;
close FQB;
close OUA;
close OUB;
system("rm -rf $$");

if( keys %tags ){
    print STDERR "Job Finished with ERRORs:\n";
    foreach my $id( keys %tags ){
        print STDERR "\t$id\n";
    }
}else{
    print STDERR ".Mission Complete.";
}


sub usage{
    print STDERR "\e[;32;1m
    DESCRIPTION
        \e[4m Under Line \e[;32;1m
    USAGE

    OPTIONS
    -i  valid pair list
    -1  read1
    -2  read2
    -3  output r1
    -4  output r2

    VERSION 1.0 Wed Jun 28 12:56:36 CST 2017
    AUTHOR  Yang Xianwei <yangxianwei1988\@gmail.com>\e[0m
    \n";
}


