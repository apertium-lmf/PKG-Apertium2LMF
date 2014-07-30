#!/usr/bin/perl -w

###################################################################################################
# This script takes an expanded monolingual Apertium lexicon (lt-expand apertium.dix > apertium.expanded) 
# and generates the corresponding LMF version. 
#
# Only standard entries are included (form:lemma<tag><tag>...). This excludes  
# compositional multiwords and restrictec entries.
#
# In the Apertium expanded lexicons, the first <tag> corresponds to the part of speech. The rest of tags 
# (all enclosed in angle brackets) encode additional morphosyntactic information depending on the pos and 
# lemma. ex:  pizzas:pizza<n><f><pl>
#
# 
# In the resulting LMF lexicon, part of speech is encoded as '<feat att="partOfSpeech" val="tag">'. 
# For other tags:
#
# a) if --tags option is active: 'att' names are read from ApertiumMonolingualTags.pm, thus in the eample 
#    above we get: <feat att="gender" val="f"> <feat att="number" val="pl">
# 
# b) if --tags option is NOT active: att names are generated as follows::
#  '<feat att="tag1" val="f">' <feat att="tag2" val="pl">'.
#
# Edit ApertiumMonolingualTags.pm file as required to generate the desired 'att' names.
#
#
# (January 2011, Marta Villegas IULA UPF)
###################################################################################################


use IO::File;
use File::Basename;
use Switch;
use Getopt::Long    qw(GetOptions);
use utf8;


################################## program options ##############################################
my %UserOptions;                	

if ( ! GetOptions( \%UserOptions,
                   "file=s",          ## apertium expanded diccionary to process
                   "lang=s",          ## language 
		   "tags",	      ## tags
                   "help|ajuda|ayuda", \&Help,
                   "<>", \&ErrorValue)  )   {
                   print STDERR "Atenció! Error en la lectura de las opciones.";
                   &Help();
                   exit -1;
} 

if ( ! defined($UserOptions{'file'})  ) {
    print STDERR "\nAlert!!!! not defined input file.\n"; &Help();
    exit -1;
}
if ( ! defined($UserOptions{'lang'})  ) {
    print STDERR "\nAlert!!!! not defined language.\n"; &Help();
    exit -1;
}
if ( defined($UserOptions{'tags'})  ) {
    use ApertiumMonolingualTags;
}
################################## program ##############################################
open FILE, "<$UserOptions{'file'}" or die $!; 

&printHeader($UserOptions{'lang'});

my $lastlema ="000";
my $lastpos = "";

my $id =  "1";
my $tail = "";
my $end;

while(<FILE>){
	chomp;
	
	#### we get the 'tail' of multiword entries (those with #)
	
	if ($_ =~ /(.*)\#(.*)$/){	$tail = $2; } else { $tail = ""; }

	#### only 'standard' "form:lemma<tag>..." lines are considered (unrestricted generated forms)
	#### we don't want compositional multiwords (+) nor regular expressions

	if ($_ =~ /(.*)\+(.*)/ || $_ =~ /(.*)REGEXP(.*)/) {
	} else {
			
		my @fields = split(/:/,$_);
		my $size = @fields;
	
		### only 'regular' lemma:form<tag>.... lines are included (we exclude restricted entries (:<: and :>:)
		if ($size == 2) {			
			my @tags = split (/</,$fields[1]);
			my $lemma = shift(@tags);
			$lemma = $lemma.$tail;
			my $posTag = shift(@tags);
			chop($posTag);
			my $wordForm = $fields[0];
			my $numtags = @tags;

			if ( $lastlema eq "000"  ){  $end = ""; } else {  $end = "</LexicalEntry>\n"; } 	## Just to close the firts LexicalEntry

			if ( $lemma eq $lastlema && $posTag eq $lastpos ){ 				## Still in the same LexicalEntry
				
				&printWordForm($wordForm,@tags);
		
			} else {  									## New LexicalEntry
				print "$end<LexicalEntry  id=\"id$id-s\">\n";
				print "\t<feat att=\"partOfSpeech\" val=\"$posTag\"/>\n";
				print "\t<Lemma>\n";
				print "\t\t<feat att=\"writtenForm\" val=\"". &render($lemma) . "\"/>\n";
				print "\t</Lemma>\n";
				&printWordForm($wordForm,@tags);
				$id++;
				}
			$lastlema = $lemma;
			$lastpos = $posTag;
		}
	}

}

print "</LexicalEntry>\n</Lexicon>\n</LexicalResource>";
close FILE;

#######################################################################################################
#######################################################################################################

sub render(){
	my $form = $_[0];
	$form =~ s/&/&amp;/g; 
	return $form;
}

sub printWordForm(){

	my $wordForm = shift(@_);
	
	print "\t<WordForm>\n";
	print "\t\t<feat att=\"writtenForm\" val=\"". &render($wordForm) ."\"/>\n";
	
	### if tags option is activated, we get att names from tags.pm
	if (defined($UserOptions{'tags'})){ 
		foreach (@_) { 
			my ($val,$rest) = split(/#/,$_); 
			chop($val);print "\t\t<feat att=\"$Tags{$val}\" val=\"$val\"/>\n"; }

	### if tags option is not activated, we generate tagsN for att names
	} else{
		my $num = 1;
		foreach (@_) {
			my ($val,$rest) = split(/#/,$_);
			chop($val); print "\t\t<feat att=\"tag$num\" val=\"$val\"/>\n"; $num++;}
	}
	print "\t</WordForm>\n";

}


sub printHeader(){
	my $lang = $_[0];
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<!DOCTYPE LexicalResource SYSTEM \"DTD_LMF_REV_16.dtd\">

<LexicalResource dtdVersion=\"16\">

<GlobalInformation>
<feat att=\"description\" val=\"This lexicon was automatically generated from an expanded Apertium monolingual lexicon. 
		The Apertium monolingual lexicon was expanded with the lt-expand command. 
		Notes:
		- Only 'unrestricted' forms are included, that is forms with no left/rigth restricions. 
		- Compositional multiword forms are not included, (thus verbforms with enclitics are not included)\"/>

</GlobalInformation>

<Lexicon>
<feat att=\"language\" val=\"$lang\"/>\n\n";
}

sub ErrorValue () {
	my($Opt) = @_;
	print STDERR "$Opt: not valid value";
	print STDERR "Error in input param.";
	Help();
	exit -1;
}

sub Help () {
print STDERR <<EHELP;

$0 --file expanded Apertium file --lang language (--tags) 

Program to convert Apertium expanded dictionaries to LMF annotation
  --file dicionary          ## diccionary to process
  --lang language           ## language of the diccionary
  --tags                    ## if present, reads ApertiumMonolingualTags.pm in order to find attribute names
  --h                  	    ## this help
EHELP
exit 0;
}
	
