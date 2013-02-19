#!/usr/bin/env perl

use lib qw(/srv/www/sbcat/lib /srv/www/sbcat/lib/extension /srv/www/sbcat/lib/default /home/bup/perl5/lib/perl5);

use Catmandu -all;
use Catmandu::Sane;
use Catmandu::Store::MongoDB;
use Catmandu::Fix qw(add_ddc rename_relations move_field split_ext_ident add_contributor_info add_file_access language_info remove_field volume_sort);

use SBCatDB;
use Data::Dumper;
use luurCfg;
use Getopt::Std;
use Orms;

getopts('u:m:');
our $opt_u;
# m for multiple indices
our $opt_m;

my $cfg = luurCfg->new;
my $orm = $cfg->{ormsCfg};
my $luur = Orms->new($cfg->{ormsCfg});

if($opt_m && $opt_m eq "pub2"){
	Catmandu->load('/srv/www/sbcat/PUBSearch/index2');
}
elsif($opt_m && $opt_m eq "pub1"){
	Catmandu->load('/srv/www/sbcat/PUBSearch/index1');
}
else {
	Catmandu->load;
}

my $conf = Catmandu->config;

my $pre_fixer = Catmandu::Fix->new(fixes => [
			'rename_relations()',
			'add_contributor_info()',
			'split_ext_ident()',
			'move_field("type.typeName","documentType")',
			'add_file_access()',
			'language_info()',
			'add_ddc()',
			'volume_sort()',
		]);

my $post_fixer = Catmandu::Fix->new (fixes => [
			'remove_field("type")',
			'remove_field("usesLanguage")',
			'remove_field("citations._id")',
			'remove_field("additionalInformation")',
			'remove_field("message")',
			'remove_field("citations._id")',
			'hiddenFor_info()',
		]);
		
my $bag = Catmandu->store('search')->bag('publicationItem');
my $citbag = Catmandu->store('citation')->bag;

my $db = SBCatDB->new({
    config_file => "/srv/www/sbcat/conf/extension/sbcatDb.pl",
    db_name  => $orm->{ormsDb},
    host     => $orm->{ormsDbHost},
    username => $orm->{ormsDbUser},
    password => $orm->{ormsDbPassword},
});

sub add_to_index {
	my $rec = shift;

	$pre_fixer->fix($rec);
	$rec->{citation} = $citbag->get($rec->{_id}) if $rec->{_id};
	$post_fixer->fix($rec);
	($rec->{project}) && ($rec->{proj} = 1);
	$bag->add($rec);
}

if ($opt_u)  { # update process

	my $q = "(submissionStatus exact public OR submissionStatus exact returned) AND dateLastChanged > \"$opt_u\"";
    my $results = $db->find($q);
    while (my $rec = $results->next) {
    	if($rec->{usesMainFile}->[0]){
    		`/srv/www/sbcat/PUBSearch/bin/make_thumbnails.pl -i $rec->{oId}`;
    	}
    	add_to_index($rec);
    }
    
} else { # initial indexing

	# get all publication types
	my $types = $luur->getChildrenTypes(type => 'publicationItem');

	# foreach type get public records
	foreach (@$types) {
		my $obj = $luur->getObjectsByAttributeValues(type => $_, attributeValues => {submissionStatus => 'public'});
		foreach (@$obj) {
			add_to_index($db->get($_));
		}
	}

}

$bag->commit;
#say "Processed records: $count";

=head1 SYNOPSIS

Script for indexing publication data

=head2 Initial indexing

perl index_publication.pl

# fetches all data from SBCatDB and pushes it into the search store

=head2 Update process

perl index_publication.pl -u 'DATETIME'

# fetches all records with dateLastChanged > 'DATETIME' (e.g. 2012-10-15 21:34:02) and pushes it into the search store

=head1 VERSION

0.02, Oct. 2012

=cut
