package PUBSearch::URI;

use Catmandu::Sane;
use Dancer qw(:syntax);

#hook before => sub {
#    my $params = params;
#    if (delete $params->{iframe}) {
#        $params->{embed} = 1;
#    }
#    if (my $q = delete $params->{cql_qs}) {
#        $params->{q} = $q;
#    }
#};

#get '/get/:id' => sub {
#    forward '/publication/'.params->{id};
#};

#get '/record/:id' => sub {
#    forward '/publication/'.params->{id};
#};

#get '/dublin_core/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'dc'};
#};

#get '/dc/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'dc'};
#};

#get '/mods/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'mods'};
#};

#get '/mets/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'mets'};
#};

#get '/didl/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'didl'};
#};

#get '/json/:id' => sub {
#    forward '/publication/'.params->{id}, {fmt => 'json'};
#};

#get '/classification/rss/:term' => sub {
#    my $classification = param 'classification';
#    forward '/feed/daily', {q => "classification exact $classification"};
#};

#get '/organization/rss/:ugent_id' => sub {
#    my $ugent_id = param 'ugent_id';
#    forward '/feed/daily', {q => "affiliation exact $ugent_id"};
#};

#get '/project/rss/:id' => sub {
#    my $id = param 'id';
#    forward '/feed/daily', {q => "project.id exact $id"};
#};

#get '/person/rss/:id' => sub {
#    my $id = param 'ugent_id';
#    forward '/feed/daily', {q => "author exact $id or (type exact bookEditor and editor exact $id)"};
#};

# fft demonstrator
#get '/fft' => sub {
#	template 'fft_demo';
#};

# publications by document type
get '/type/:type' => sub {
	my $t = param 'type';
	forward '/publication', {q => "documenttype=$t"};
};


# publications by year
get '/year/:year' => sub {
	my $y = param 'year';
	forward '/publication', {q => "publishingYear exact $y"};
};

# oa: all open access fulltexts
get '/oa' => sub {
	forward '/publication', {q => "fulltext exact 1"};
};

get '/oa/type/:type' => sub {
	my $t = param 'type';
	forward '/publication', {q => "fulltext exact 1 AND documenttype=$t"};
};

get '/oa/year/:year' => sub {
	my $y = param 'year';
	forward '/publication', {q => "fulltext exact 1 AND publishingYear exact $y"};
};

get '/oa/person/:id' => sub {
	my $id = param 'id';
	forward '/publication', {q => "fulltext exact 1 AND person exact $id"};
};

get '/oa/department/:id' => sub {
	my $id = param 'id';
	forward '/publication', {q => "fulltext exact 1 AND department exact $id"};
};

#get qr{/group((?:/\d+)+)} => sub {
#    my ($ugent_id) = splat;
#    substr $ugent_id, 0, 1, "";
#    $ugent_id =~ s!/!,!g;
#    forward "/group/$ugent_id";
#};

get '/m' => sub {
    forward '/';
};

get '/m/*/*' => sub {
    my ($path, $term) = splat;
    forward "/$path/$term";
};

1;