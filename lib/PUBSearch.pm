package PUBSearch;

use lib
  qw(/srv/www/sbcat/lib /srv/www/sbcat/lib/extension /srv/www/sbcat/lib/default);
use Catmandu::Sane;
use Dancer qw(:syntax);
use Dancer::Request;
use Template;
use Catmandu;
use Catmandu::Util qw(:array);
use Catmandu::Store::ElasticSearch;
use LWP::UserAgent;

Catmandu->load;

use SBCatDB;

#hook before => sub {
#    my $header_accept = request->{accept};
#    $header_accept =~ s/;.*//g;
#    my @accepts = split (',', $header_accept);
#    params->{accepts} = \@accepts; 	
#};

use PUBSearch::Helper;
use PUBSearch::SRU;
use PUBSearch::URI;
use PUBSearch::Directoryindex;
use PUBSearch::Entity;
use PUBSearch::Mark;
use PUBSearch::Feed;
use PUBSearch::OAI;
use PUBSearch::Thumbnail;

our $VERSION = '1.01';

####################
### setup        ###
####################
my $default_style = "ama";
my $fd_style = "ama";


#############################################################
### Dancer Route Handling
#############################################################

get qr{/search/*} => sub {
	template 'portal/bup_smask.tmpl', {search_docs => h->config->{lists}->{search_docs_public}, search_lang => h->config->{lists}->{search_lang}, pagination_opts => h->config->{store}->{pagination_options}};
};

####################
### publications ###
####################

####################
# this route must appear before the other routes
# otherwise Dancer won't find it due to regex
####################
#get '/publication/:id/preview' => sub {
get qr{/publication/(\d{1,})/preview/*} => sub {
	
	my $tmpl;
	
	$tmpl = "record";
	
	my ($id)    = splat;

	my $citeBag = Catmandu->store('citation')->bag;
	my $citations = $citeBag->get($id);
	
	my $sbcatDB = SBCatDB->new({
		config_file => "/srv/www/sbcat/conf/extension/sbcatDb.pl",
		db_name     => "[db_name]",
		host        => "[db_host]",
		username    => "[db_user]",
		password    => "[db_password]",
	});
	my $rec       = $sbcatDB->get($id);
	my $dateSB = $rec->{dateLastChanged};
	
	my $p = {
		q => "id=$id",
		start => 0,
		limit => 10,
	};
	my $hits = h->search_publication($p);
	my $dateES = "1900-01-01 12:00:00";
	$dateES = @{$hits->{hits}}[0]->{dateLastChanged} if @{$hits->{hits}}[0];
	
	if ($dateSB eq $dateES){
		my $servername = request->uri_base;
		$servername =~ s/:5000//g;
		$servername =~ s/pub2\.ub/pub/g;
		redirect "$servername/publication/$id";
	}
	else {
		$rec->{citation} = $citations;
		$rec->{style}     = $fd_style;
		$rec->{preview}   = 'preview';
		$rec->{display_docs} = config->{lists}->{display_docs};
		
		template $tmpl, $rec;
	}
	
};

# splash page style param '/publication/:id/:style'
get qr{/publication/(\d{1,})/(\w{1,})/*} => sub {
	my ($id, $style) = splat;
	
	my $tmpl;
	
	$tmpl = "record";
		
	forward '/publication', {q => "id=$id", style => $style, limit => 1, tmpl => $tmpl };
};

# splash page '/publication/:id'
get qr{/publication/(\d{1,})/*} => sub {
	my ($id) = splat;
	
	my $tmpl;
	
	$tmpl = "record";
		
	forward '/publication', {q => "id=$id", limit => 1, style => $fd_style, tmpl => $tmpl};
};

get qr{/publication/$} => sub {
	forward '/search';
};

# api for publication lists
get '/publication' => sub {

	my %paramhash = params;
	if(!%paramhash){
		forward '/search';
	}
	
	my $sort = params->{'sort'} ||= '';
	my $fmt  = params->{fmt} ||= 'html'; 
	my $tmpl = params->{tmpl} ||= 'pubList';
	
	my $start = params->{start} ||= 0;
	my $limit = params->{limit} ||= h->config->{store}->{default_page_size};
	
	my $style = $default_style;#params->{style} ||= $default_style;
	if(params->{style}){
		$style = params->{style};
	}
	else {
		$style = $fd_style if params->{limit} eq 1;
		$style = $default_style if params->{limit} ne 1;
	}
	
	my $cqlsort;
	if($sort =~ /(\w{1,})\.(\w{1,})/){
		$cqlsort = $1 . ",,";
		$cqlsort .= $2 eq "asc" ? "1" : "0";
	}
	
	my $p = {
		q => params->{q},
		start => $start,
		limit => $limit,
	};
	$p->{'sort'} = $cqlsort if $cqlsort;
	
	my $hits = h->search_publication($p);
	
	if(!$hits){
		template 'error';
	}
	
	$hits->{style} = $style;
	$hits->{q} = params->{q} if params->{q};
	
	if ( $fmt eq 'html' ) {
		if (params->{ftyp}) {
			$tmpl .= "_". params->{ftyp};
			header("Content-Type" => "text/plain") unless params->{ftyp} eq 'iframe';
			$tmpl .= "_num" if (params->{enum} and params->{enum} eq "1");
			template $tmpl, $hits;
		}
		 
		if($limit == 1 && @{$hits->{hits}}[0]){
			@{$hits->{hits}}[0]->{style} = $style;
			template $tmpl, @{$hits->{hits}}[0];
		} else {
			template $tmpl, $hits;
		}
	}
	else {
		h->export_publication( $hits, $fmt );
	}
	
};

#######################
#### wos api ##########
#######################

get '/info/times-cited' => sub {

	my $ut = param('ut');
    	my $wosURL = 'http://apps.webofknowledge.com/';

    	my $body = <<XML;
<?xml version="1.0" encoding="UTF-8" ?>
<request xmlns="http://www.isinet.com/xrpc41">
<fn name="LinksAMR.retrieve">
<list>
<map>
</map>
<map>
  <list name="WOS">
    <val>timesCited</val>
    <val>citingArticlesURL</val>
  </list>
</map>
<map>
  <map name="cite_id">
    <val name="ut">$ut</val>
  </map>
</map>
</list>
</fn>
</request>
XML

    	my $ua = LWP::UserAgent->new;
    	my $xml = $ua->post('https://ws.isiknowledge.com/cps/xrpc', Content => $body);
    	my ($times_cited) = $xml->{_content} =~ /<val\s+name=['"]timesCited['"]\s*>(\d+)/;
    	my ($citingArticlesURL) = $xml->{_content} =~ /CDATA\[(.*)\]\]/;
    	content_type 'application/json';
    	to_json {
           times_cited => $times_cited ? $times_cited+0 : 0,
           citingArticlesURL => $citingArticlesURL ? $citingArticlesURL : $wosURL,
    	};

};

1;
