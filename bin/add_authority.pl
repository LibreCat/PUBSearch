#!/usr/bin/env perl

use lib qw(/srv/www/sbcat/lib /srv/www/sbcat/lib/extension /srv/www/sbcat/lib/default /home/bup/perl5/lib/perl5);
use Catmandu -all;
use Catmandu::Sane;
use Catmandu::Fix;
use Catmandu::Util qw(as_utf8);
use Catmandu::Importer::JSON;
use Orms;
use luurCfg;
use LWP::Simple;
use Getopt::Std;
use Data::Dumper;
##################################
### DON'T CHANGE SCRIPTNAME!
### If you do change its name, also change the command in
### controllers/default/Module/Authority/Author.pm line 541
### AND
### controllers/default/Module/Preferences.pm line 55
##################################

my $cfg = luurCfg->new;
my $luur = Orms->new($cfg->{ormsCfg});
my $default_style = $cfg->{citation_db}->{default_style};

Catmandu->load;
my $conf = Catmandu->config;
my $bag= Catmandu->store('authority')->bag;
my $host = $conf->{host};

getopts('adp:');
our ($opt_a, $opt_d, $opt_p);

# main #
if($opt_p) {
	&add_person($opt_p);
} elsif ($opt_d) {
	&add_department;
} elsif ($opt_a) {
	&add_person;
#	&add_department;
}

sub add_department {
	
	my $fixer = Catmandu::Fix->new(fixes => [
		'move_field("organizationNumber", "_id")',
		'add_field("type", "organization")',
		]);
	my $dep_list = $luur->getObjectsByType(type => 'luOrganization');
	foreach (@$dep_list) {
		my $dep = $luur->getAttributeValues(object => $_);
		print Dumper $dep;

	}

	my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
    #$data->{dateLastChanged} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $day, $hour, $min, $sec);
	#$fixer->fix($data);
	#($data) && ($bag->add($data));
}

sub add_person {

   my $id = shift;
   my $fixer = Catmandu::Fix->new(fixes => [
		'add_citation_preference()',
		'move_field("personNumber", "_id")',
		'remove_field("luLdapId")',
		'add_field("type", "person")',
		]);

   if($id) {
	my $person = $luur->getObjectsByAttributeValues(type => 'luAuthor', attributeValues => { personNumber => $opt_p});
	my $data = $luur->getAttributeValues(object => @{$person}[0]);
	
	my $affil    = $luur->getRelatedObjects(object1  => @{$person}[0], relation => 'isAffiliatedWith');
	foreach (@$affil) {
		my $dep = $luur->getAttributeValues(object => $_);
		my $name = $dep->{name};
		if (ref $name eq 'ARRAY') {
			push @{$data->{affiliation}}, {name => $dep->{name}->[0], organizationNumber => $dep->{organizationNumber}};
		} else {
			push @{$data->{affiliation}}, {name => $dep->{name}, organizationNumber => $dep->{organizationNumber}};
		}
	}
	$data->{sbcatId} = $person->[0];
	my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
    $data->{dateLastChanged} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $day, $hour, $min, $sec);
	$fixer->fix($data);

	($data) && ($bag->add($data));
   } else {
	my $person = $luur->getObjectsByType(type => 'luAuthor');
	
	foreach my $p (@$person) {
	   my $data = $luur->getAttributeValues(object => $p);
	   my $affil    = $luur->getRelatedObjects(object1  => $p, relation => 'isAffiliatedWith');
	   foreach (@$affil) {
	      my $dep = $luur->getAttributeValues(object => $_);
	      my $name = $dep->{name};
	      if (ref $name eq 'ARRAY') {
		 push @{$data->{affiliation}}, {name => $dep->{name}->[0], organizationNumber => $dep->{organizationNumber}};
	      } else {
	         push @{$data->{affiliation}}, {name => $dep->{name}, organizationNumber => $dep->{organizationNumber}};
	      }
	   }
	   $data->{sbcatId} = $p;
	   my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
	   $data->{dateLastChanged} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $day, $hour, $min, $sec);
	   $fixer->fix($data);
		
	   ($data) && ($bag->add($data));
	}
   }

}

=head1 SYNOPSIS

Script for indexing authority data

=head2 Create/refresh authority store

bin/add_authority.pl

bin/add_authority.pl -r

=head2 Update store with a person's infos 

bin/add_authority.pl -p [person's BIS ID]

=head1 VERSION

0.02, Feb. 2013, vitali

=cut
