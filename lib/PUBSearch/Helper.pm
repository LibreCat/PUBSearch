package PUBSearch::Helper::Helpers;
use lib qw(/srv/www/sbcat/lib/default);

use Catmandu::Sane;
use Catmandu qw(:load export_to_string);
use Catmandu::Util qw(:is :array);
use Dancer qw(:syntax vars params request);
use Template;
use Moo;
use LWP::Simple;
use HTML::Entities;

sub config {
    state $config = Catmandu->config;
}

sub publications {
	state $bag = Catmandu->store('search')->bag('publicationItem');
}

sub projects {
	state $bag = Catmandu->store('search')->bag('project');
}

sub award {
    state $bag = Catmandu->store('search')->bag('award');
}

sub authority {
    state $bag = Catmandu->store('authority')->bag;
}

sub europmc {
	state $bag = Catmandu->store('europmc')->bag;
}

sub response_format {
   my ($self) = @_;
   my $accepts = params->{accepts};

   # acceptable content types
   my $mime_types;
   foreach (keys %{config->{export}->{publication}}) {
      $mime_types->{$_->{content_type}} = $_;
   }
   my %seen = ();
   my @acceptable_fmt = grep {$seen{$_}++} @$accepts, keys %$mime_types;
   my $fmt = $acceptable_fmt[0] ||= '';
   return $fmt;
}

sub getPerson {
    $_[0]->authority->get($_[1]);
}

sub getEbiData {
    my $data = $_[0]->europmc->get($_[1]);
    my $result;
    foreach my $db (@{$data->{db_links}}){
    	given ($db->{database}) {
    		when ('UNIPROT')  { push @{$result->{UniProt}}, $db}
    		when ('EMBL')     { push @{$result->{EMBL}}, $db}
    		when ('INTERPRO') { push @{$result->{InterPro}}, $db}
    		when ('PDB')      { push @{$result->{'RCSB PDB'}}, $db}
    		when ('CHEBI')    { push @{$result->{ChEBI}}, $db}
    		when ('CHEMBL')   { push @{$result->{ChEMBL}}, $db}
    		when ('INTACT')   { push @{$result->{IntAct}}, $db}
    	}
    }
    return $result;
}

sub getBISData {
    my $id = $_[1];
    # BIS API
    my $base = 'http://ekvv.uni-bielefeld.de/ws/pevz/PersonKerndaten.xml?';
    my $base2 = 'http://ekvv.uni-bielefeld.de/ws/pevz/PersonKontaktdaten.xml?';
    my $url = $base . "persId=$id";
    my $url2 = $base2 . "persId=$id";
    my $res = get($url);
    my $res2 = get($url2);
    my ($photo) = $res =~ /bildskalierturl>(.*?)<\/pevz:bildskalierturl/g;
    my ($personTitle) = $res =~ /titel>(.*?)<\/pevz:titel/g;
    my ($personName) = $res =~ /nachname>(.*?)<\/pevz:nachname/g;
    my ($email) = $res2 =~ /email_verschleiert>(.*?)<\/pevz:email_verschleiert/g;
    decode_entities ($email) if $email;
    my $former = $email ? 0: 1;
    my $nonexist = ($former and !$personName) ? 1 : 0;
    my $forschend = ($res =~ /forschend="forschend"/) ? 1 : 0;
    return {photo => $photo, email => $email, forschend => $forschend, former => $former, nonExist => $nonexist, personTitle => $personTitle};
}

sub string_array {
    my ($self, $val) = @_;
    return [ grep { is_string $_ } @$val ] if is_array_ref $val;
    return [ $val ] if is_string $val;
    [];
}

sub display_doctypes {
	my $map = config->{lists}{display_docs};
	my $doctype = $map->{lc $_[1]};
	$doctype;
}

sub display_gs_doctypes {
	my $map = config->{lists}{display_gs_docs};
	my $doctype = $map->{lc $_[1]};
	$doctype;
}

sub display_publstatus {
	my $map = config->{lists}{display_publstatus};
	my $publstatus = $map->{lc $_[1]};
	$publstatus;
}

sub display_styles {
	my $map = ["ama", "apa", "ieee"];
	$map;
}

sub host {
	my $serverIP = request->address();
	my $host = config->{env}->{$serverIP}->{host};
	return $host;
}

sub shost {
	my $serverIP = request->address();
	my $host = config->{env}->{$serverIP}->{host};
	$host =~ s/http/https/g;
	return $host;
}

sub sort_options {
    state $sort_options = do {
        my $sorts = $_[0]->config->{sort_options} || [];
        List::Util::reduce {
            $a->{"$b->{key}.$b->{order}"} = $b; $a;
        } +{}, @$sorts;
    };
}

sub is_marked {
	my ($self, $id) = @_;
	my $marked = Dancer::session 'marked';
	return Catmandu::Util::array_includes($marked, $id);
}

sub extract_search_params {
    my ($self, $params) = @_;
    $params ||= params;
    my $p = {};
    $p->{start} = $params->{start} if is_natural $params->{start};
    $p->{limit} = $params->{limit} if is_natural $params->{limit};
    $p->{q} = $self->string_array($params->{q});
	
  #  my $sort = $self->string_array($params->{sort});
  #  $sort = [ grep { exists $self->sort_options->{$_} } map { s/(?<=[^_])_(?=[^_])//g; lc $_ } split /,/, join ',', @$sort ];
  #  $sort = [] if is_same $sort, $self->config->{store}{default_sort};
  #  $p->{sort} = $sort;
	
	#$p->{tmpl} = $params->{tmpl} if is_string $params->{tmpl} ||= 'pubList';
	#$p->{style} = $params->{tmpl} if is_string $params->{tmpl};
	#$p->{format} = $params->{tmpl} if is_string $params->{tmpl};
	
	#$sort_params = $self->config->{store}{default_sort} unless @$sort_params;
    #my $sort = [ map {
    #    my $spec = $self->sort_options->{$_};
    #    my $val = {order => $spec->{order}};
    #    $val->{missing} = $spec->{missing} if exists $spec->{missing};
    #    +{$spec->{field} => $val};
   # } @$sort_params ];

    $p;
}

#sub process_sort_param {
#	my $sort_params = $params->{sort};
#    $sort_params = $self->config->{default_publication_sort} unless @$sort_params;
#    my $sort = [ map {
#        my $spec = $self->sort_options->{$_};
#        my $val = {order => $spec->{order}};
#        $val->{missing} = $spec->{missing} if exists $spec->{missing};
#        +{$spec->{field} => $val};
#    } @$sort_params ];
#    $sort;
#
#}

sub search_params {
    my ($self, $params) = @_;
    if ($params) {
        return vars->{search_params} = $self->extract_search_params($params);
    }
    vars->{search_params} ||= $self->extract_search_params;
}

sub search_publication {
	
	my ($self, $p) = @_;
	my $hits;
	my $q = $p->{q} ||= "";
	($q eq '') ? ($p->{q} = "submissionStatus exact public") 
		: ($p->{q} .= " AND submissionStatus exact public");
	my $default_sort = "";
	foreach (@{config->{store}->{default_sort}}){
		$default_sort .= "$_->{field},,";
		$default_sort .= $_->{order} eq "asc" ? "1 " : "0 ";
	}
	$default_sort = substr($default_sort, 0, -1);
	
	my $sort = $p->{'sort'} ||= $default_sort;
	$hits = publications->search(
		cql_query => $p->{q},
		sru_sortkeys => $sort,
	    limit => $p->{limit} ||= config->{default_page_size},
       	start => $p->{start} ||= 0,
       	facets => $p->{facets} ||= {},
    );
       	
    foreach (qw(next_page last_page page previous_page pages_in_spread)) {	
    	$hits->{$_} = $hits->$_;
    }
	
	return $hits;
	
}

sub search_project {
	
	my ($self, $p) = @_;
	my $hits;
	
	$hits = projects->search (
		cql_query => $p->{q},
		limit => $p->{limit} ||= config->{default_page_size},
       	start => $p->{start} ||= 0,
	);
	
	foreach (qw(next_page last_page page previous_page pages_in_spread)) {
        $hits->{$_} = $hits->$_;
    }
    
    return $hits;
}

sub export_publication {
	
	my ($self, $hits, $fmt) = @_;
	
	# special treatment, due to problems with Catmandu::Exporter::Template
	#if ($fmt eq'rdf') {
	  # my $rdf_specs = config->{export}->{publication}->{rdf};
	  # my $tmpl = $rdf_specs->{options}->{template};
	  # return Template::template( $tmpl, $hits->{hits});
	   #my $ext = $rdf_specs->{extension};
	  # return Dancer::send_file(
	  #    \$data,
	  #    content_type => $rdf_specs->{content_type},
	  #    filename => "publications.$ext",
	  # );
	#} 
        if ( my $spec = config->{export}->{publication}->{$fmt} ) {
	   my $package = $spec->{package};
	   my $options = $spec->{options} || {};
	   if($hits->{style} and $hits->{style} ne "frontShort"){
			$options->{style} = $hits->{style};
	   }
	   else {
	      $options->{style} = "ama";
	   }
	   my $content_type = $spec->{content_type} || mime->for_name($fmt);
	   my $extension    = $spec->{extension} || $fmt;

  	   my $f = export_to_string( $hits->{hits}, $package, $options );
	   return Dancer::send_file (
   	      \$f,
	      content_type => $content_type,
	      filename     => "publications.$extension"
	   );
	}

}

sub export_in_frontdoor {
	my ($self, $id, $fmt) = @_;
	my $hits = $self->search_publication({q => "id=$id"});
	if ( my $spec = config->{export}->{publication}->{$fmt} ) {
		my $package = $spec->{package};
		my $options = $spec->{options} || {};
		
		my $f = export_to_string( $hits->{hits}, $package, $options );
		($fmt eq 'bibtex') ? $f =~ s/\n/<br \/>&emsp;&emsp;/g 
			: $f =~ s/\n/<br \/>/g;
	# quick fix; TODO: handle umlauts in exporter module (problem is located in LaTeX::Encode)
		if ($fmt eq 'bibtex') {
			$f =~ s/(\\"\w)\s/{$1}/g;
			$f =~ s/&emsp;&emsp;\}<br \/>&emsp;&emsp;<br \/>&emsp;&emsp;$/}/g;
		}
		utf8::decode($f);
		return $f; 
	}		
}

sub embed_string {
	my ($self, $query, $id, $style, %params) = @_;
	my $embed;
	my $host = $_[0]->host();
	delete $params{splat};
	
	if(keys %params){
		# create a javaScript snipped for this list
		my $ftyp = '&ftyp=js';
		my $stylestring = "&style=";
		$stylestring .= $style if $style;
		
		my $sortstring = "";
		if($params{sort}){
			if (ref $params{sort} eq 'ARRAY'){
				foreach (@{$params{sort}}){
					$sortstring .= "&sort=$_";
				}
			}
			else{
				$sortstring = "&sort=$params{sort}";
			} 
		}
		
		my $string1 = '&lt;div class="publ"&gt;&lt;script type="text/javascript" charset="UTF-8" src="' . $host . '/publication?q=';
		my $string2 = '"&gt;&lt;/script&gt;&lt;noscript&gt;&lt;a href="' . $host . '/publication?q=';
		my $string3 = '" target="_blank"&gt;Pers&amp;ouml;nliche Publikationsliste &gt;&gt; / My Publication List &gt;&gt;&lt;/a&gt;&lt;/noscript&gt;&lt;/div&gt;';
		
		#$embed->{modjs} = $string1 . $query . $ftyp . $stylestring . $sortstring . $string2 . $query . $stylestring . $sortstring . $string3;
		$embed->{js} = $string1 . $query . $ftyp . $stylestring . $sortstring . $string2 . $query . $stylestring . $sortstring . $string3;
		$string1 = ""; $string2 = ""; $string3 = ""; $ftyp = "";
		
		
		# create an iFrame containing this list
		$ftyp = "&ftyp=iframe";
		$string1 = '&lt;iframe id="pubIFrame" name="pubIFrame" frameborder="0" width="726" height="300" src="' . $host . '/publication?q=';
		$string2 = '"&gt;&lt;/iframe&gt;';
		
		#$embed->{modiframe} = $string1 . $query . $ftyp . $stylestring . $sortstring . $string2;
		$embed->{iframe} = $string1 . $query . $ftyp . $stylestring . $sortstring . $string2;
		$string1 = ""; $string2 = "";
		
		
		# create a link to this page
		$string1 = '&lt;a href="' . $host . '/person/'. $id . '?';
		$string2 = '"&gt;My Publication List&lt;/a&gt;';
		
		my $linkstring = $string1;
		foreach my $key (keys %params){
			next if $key eq 'splat';
			if(ref $params{$key} eq 'ARRAY'){
				foreach (@{$params{$key}}){
					$linkstring .= "$key=$_&";
				}
			}
			else {
				$linkstring .= "$key=$params{$key}&";
			}
		}
		#$embed->{'modlink'} = $linkstring . $string2;
		$embed->{'link'} = $linkstring . $string2;
	}
	
	else {
	# create a javaScript snipped for this list
	my $ftyp = '&ftyp=js';
	my $stylestring = "&style=";
	$stylestring .= $style if $style;
	
	my $string1 = '&lt;div class="publ"&gt;&lt;script type="text/javascript" charset="UTF-8" src="' . $host . '/publication?q=';
	my $string2 = '"&gt;&lt;/script&gt;&lt;noscript&gt;&lt;a href="' . $host . '/publication?q=';
	my $string3 = '" target="_blank"&gt;Pers&amp;ouml;nliche Publikationsliste &gt;&gt; / My Publication List &gt;&gt;&lt;/a&gt;&lt;/noscript&gt;&lt;/div&gt;';
		
	$embed->{js} = $string1 . "person=$id" . $ftyp . $stylestring . $string2 . "person=$id" . $stylestring . $string3;
	$string1 = ""; $string2 = ""; $string3 = ""; $ftyp = "";
		
		
	# create an iFrame containing this list
	$ftyp = "&ftyp=iframe";
	$string1 = '&lt;iframe id="pubIFrame" name="pubIFrame" frameborder="0" width="726" height="300" src="' . $host . '/publication?q=';
	$string2 = '"&gt;&lt;/iframe&gt;';
		
	$embed->{iframe} = $string1 . "person=$id" . $ftyp . $stylestring . $string2;
	$string1 = ""; $string2 = "";
		
		
	# create a link to this page
	$string1 = '&lt;a href="' . $host . '/person/'. $id;
	$string2 = '"&gt;My Publication List&lt;/a&gt;';
	
	$embed->{'link'} = $string1 . $string2;
	}
	
	return $embed;
}

sub thumbnail_url {
	my ($self, $id, $name) = @_;
	my $shortname = $name;
	$shortname =~ s/\.\w{1,4}$//g;
	my $filename = "/path/to/your/thumbnails/$id/$shortname.png";
	if (-e $filename) {
		return "/thumbnail/$id/$name";
	}
	else{
		return "no_thumb";
	}
}

sub embed_params {	
	my ($self) = @_;
    vars->{embed_params} ||= do {
    	my $p = {};
        for my $key (qw(embed hide_pagination hide_info hide_options)) {
            $p->{$key} = 1 if params->{$key};
        }
        for my $key (qw(style)) {
            $p->{$key} = params->{$key} if is_string(params->{$key});
        }
        $p;
    };
}

sub parse_path {
    my ($self, $path) = @_;
    (fileparse($path, qr/\.[^\.]*/))[1,0,2];
}

sub path           { my ($self, $path) = @_; ($self->parse_path($path))[0] }
sub file_base_name { my ($self, $path) = @_; ($self->parse_path($path))[1] }
sub file_extension { my ($self, $path) = @_; ($self->parse_path($path))[2] }



sub uri_for {
    my ($self, $path, $uri_params) = @_;
    $uri_params ||= {};
    $uri_params = {%{$self->embed_params}, %$uri_params};
    #my $uri = $self->host . $path . "?";
    my $uri = $path . "?";
    foreach (keys %{ $uri_params }) {
	$uri .= "$_=$uri_params->{$_}&";
    }
    $uri =~ s/&$//; #delete trailing "&" 
    $uri;
}

sub newuri_for {
	my ($self, $path, $uri_params, $passedparam) = @_;
	my $passed_key; my $passed_value;
	foreach (keys %{$passedparam}){
		$passed_key = $_;
		$passed_value = $passedparam->{$_};
	}
	
	my $uri = $path . "?";
	
	if(defined $uri_params->{$passed_key}){
		foreach my $urikey (keys %{$uri_params}){
			if ($urikey ne $passed_key){
				if (ref $uri_params->{$urikey} eq 'ARRAY'){
					foreach (@{$uri_params->{$urikey}}){
						$uri .= "$urikey=$_&";
					}
				}
				else {
					$uri .= "$urikey=$uri_params->{$urikey}&";
				}
			}
			else { # $urikey eq $passed_key
				if($passed_key eq "person" or $passed_key eq "author" or $passed_key eq "editor" or $passed_key eq "publicationtype" or $passed_key eq "publishingyear" or $passed_key eq "sort"){
					if (ref $uri_params->{$urikey} eq 'ARRAY'){
						foreach (@{$uri_params->{$urikey}}){
							$uri .= "$urikey=$_&" unless $passed_value eq "";
						}
					}
					else {
						$uri .= "$urikey=$uri_params->{$urikey}&" unless $passed_value eq "";
					}
					$uri .= "$passed_key=$passed_value&" unless $passed_value eq "";
				}
				else {
					$uri .= "$passed_key=$passed_value&" unless $passed_value eq "";
				}
			}
		}
	}
	else {
		foreach my $urikey (keys %{$uri_params}){
			if (ref $uri_params->{$urikey} eq 'ARRAY'){
				foreach (@{$uri_params->{$urikey}}){
					$uri .= "$urikey=$_&";
				}
			}
			else {
				$uri .= "$urikey=$uri_params->{$urikey}&";
			}
		}
		$uri .= "$passed_key=$passed_value&";
	}
	
	$uri =~ s/&$//;
	$uri;
}

sub uri_for_file {
    my ($self, $pub, $file) = @_;
    my $ext = $self->file_extension($file->{fileName});
    $self->host . "/download/$pub->{_id}/$file->{fileOId}$ext";
}



package PUBSearch::Helper;

my $h = PUBSearch::Helper::Helpers->new;

use Catmandu::Sane;
use Dancer qw(:syntax hook);
use Dancer::Plugin;

register h => sub { $h };

hook before_template => sub {
	
    $_[0]->{h} = $h;
    
};

register_plugin;

1;
