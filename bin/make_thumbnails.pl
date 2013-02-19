#!/usr/bin/perl
$|++;
 
use lib "/srv/www/sbcat/lib/extension", "/srv/www/sbcat/lib/default";
use Catmandu -all;
use Catmandu::Sane;
use Orms;
use luurCfg;
use Data::Dumper;
use SBCatDB;
use Getopt::Std;
 
# max width or height of the thumbnail in pixels
my $max_thumb_size = 300;

# load configs
my $cfg = luurCfg->new;
my $orm = $cfg->{ormsCfg};
my $luur = Orms->new($cfg->{ormsCfg});
Catmandu->load;
Catmandu->config;

getopts('i:');
our $opt_i;

# all thumbnails will end up here
my $thumb_dir = config->{thumbnail_path};

my $bag = Catmandu->store('search')->bag('publicationItem');

my $db = SBCatDB->new({
    config_file => "/srv/www/sbcat/conf/extension/sbcatDb.pl",
    db_name     => $orm->{ormsDb},
    host        => $orm->{ormsDbHost},
    username    => $orm->{ormsDbUser},
    password    => $orm->{ormsDbPassword},
});

my $q = "submissionStatus exact public AND fulltext exact 1";
$q .= " AND id=$opt_i" if $opt_i;

# get all public records with fulltext
my $hits = $db->find($q);

while (my $hit = $hits->next) {

    # get filename of the first (main) file that is a pdf and openAccess
    my $filename;
    foreach (@{$hit->{usesMainFile}}){
        if ($_->{fileName} =~ /\.pdf$|\.ps$/ and $_->{accessLevel} eq 'openAccess'){
            $filename = $_->{fileName};
            last;
        }
    }

    if($filename){
        my $pub_id = $hit->{oId};
        my $filenameshort = $filename;
        $filenameshort =~ s/\.\w{2,4}$//g;
        my $dest_file = "$thumb_dir/$pub_id/$filenameshort.png";
        next if -e $dest_file;

        my $dir = $thumb_dir ."/".$pub_id;
        system "/bin/mkdir $dir" unless -e $dir;
        my $path = $cfg->{uploadDir}. "/$pub_id/" . $filename;

        system "convert -density 96 ${path}[0] $dest_file";
    }

}
