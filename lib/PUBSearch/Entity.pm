package PUBSearch::Entity;

use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Dancer qw(:syntax);
use PUBSearch::Helper;

#####################
### persons      ####
#####################
# /person/ID/
get qr{/person/(\d{1,})/*} => sub {
        
        my ($id) = splat; 
        my $tmpl = 'person';
        my $style = params->{style};
        my $fmt = params->{fmt};
        
        my $personInfo = h->getPerson($id);
        my $personStyle;
        my $personSorto;
        if($personInfo->{stylePreference}){
        	if($personInfo->{stylePreference} =~ /(\w{1,})\.(\w{1,})/){
        		$personStyle = $1 unless $1 eq "pub";
        		$personSorto = $2;
        	}
        }
        
        my $personSruSort;
        if($personSorto){
        	$personSruSort = "publishingYear,,";
        	$personSruSort .= $personSorto eq "asc" ? "1" : "0";
        } 
        my $paramSruSort = "";
        if(params->{sort} && ref params->{sort} eq 'ARRAY'){
        	foreach (@{params->{sort}}){
        		if($_ =~ /(.*)\.(.*)/){
        			$paramSruSort .= "$1,,";
        			$paramSruSort .= $2 eq "asc" ? "1 " : "0 ";
        		}
        	}
        	$paramSruSort = substr($paramSruSort, 0, -1);
        }
        elsif (params->{sort} && ref params->{sort} ne 'ARRAY') {
        	if(params->{sort} =~ /(.*)\.(.*)/){
        		$paramSruSort .= "$1,,";
        		$paramSruSort .= $2 eq "asc" ? "1" : "0";
        	}
        }
		
		my $sruSort = "";
		
		$sruSort = $paramSruSort ||= $personSruSort ||= "";
         
        my $facets = {
                coAuthor => {terms => {field => 'author.personNumber', size => 100, exclude => [$id]}},
                coEditor => {terms => {field => 'editor.personNumber', size => 100, exclude => [$id]}},
                openAccess => {terms => {field => 'file.openAccess', size => 10}},
                qualityControlled => {terms => {field => 'qualityControlled', size => 1}},
                popularScience => {terms => {field => 'popularScience', size => 1}},
                nonlu => {terms => {field => 'isNonLuPublication', size => 1}},
        };

        my $query;
        $query .= "person=$id AND hide<>$id";
        
        if(params->{author} and ref params->{author} eq 'ARRAY'){
        	foreach (@{params->{author}}){
        		$query .= " AND author exact ". $_;
        	}
        }
        elsif(params->{author} and ref params->{author} ne 'ARRAY'){
        	$query .= " AND author exact ". params->{author};
        }
        
        if(params->{editor} and ref params->{editor} eq 'ARRAY'){
        	foreach (@{params->{editor}}){
        		$query .= " AND editor exact ". $_;
        	}
        }
        elsif(params->{editor} and ref params->{editor} ne 'ARRAY'){
        	$query .= " AND editor exact ". params->{editor};
        }
        
        if(params->{person} and ref params->{person} eq 'ARRAY'){
        	foreach (@{params->{person}}){
        		$query .= " AND person exact ". $_;
        	}
        }
        elsif(params->{person} and ref params->{person} ne 'ARRAY'){
        	$query .= " AND person exact ". params->{person};
        }
        
        $query .= " AND qualitycontrolled=". params->{qualitycontrolled} if params->{qualitycontrolled};
        $query .= " AND popularscience=". params->{popularscience} if params->{popularscience};
        $query .= " AND nonlu=". params->{nonunibi} if params->{nonunibi};
        $query .= " AND fulltext=". params->{fulltext} if params->{fulltext};
        $query .= " AND basic=\"" . params->{ftext} . "\"" if params->{ftext};
        
        my $rawquery = $query;
        my $doctypequery = "";
        my $publyearquery = "";
        
        # separate handling of publication types (for separate facet)
        if(params->{publicationtype} and ref params->{publicationtype} eq 'ARRAY'){
        	my $tmpquery = "";
        	foreach (@{params->{publicationtype}}){
        		$tmpquery .= "documenttype=" . $_ . " OR ";
        	}
        	$tmpquery =~ s/ OR $//g;
        	$query .= " AND (" . $tmpquery . ")";
        	$doctypequery .= " AND (" . $tmpquery . ")";
        }
        elsif (params->{publicationtype} and ref params->{publicationtype} ne 'ARRAY'){
        	$query .= " AND documenttype=". params->{publicationtype};
        	$doctypequery .= " AND documenttype=". params->{publicationtype};
        }
        
        #separate handling of publishing years (for separate facet)
        if(params->{publishingyear} and ref params->{publishingyear} eq 'ARRAY'){
        	my $tmpquery = "";
        	foreach (@{params->{publishingyear}}){
        		$tmpquery .= "publishingyear=" . $_ . " OR ";
        	}
        	$tmpquery =~ s/ OR $//g;
        	$query .= " AND (" . $tmpquery . ")";
        	$publyearquery .= " AND (" . $tmpquery . ")";
        }
        elsif (params->{publishingyear} and ref params->{publishingyear} ne 'ARRAY'){
        	$query .= " AND publishingyear=". params->{publishingyear};
        	$publyearquery .= " AND publishingyear=". params->{publishingyear};
        }
        
        # embed string
        my $embedstyle = $style ||= $personStyle ||= "ama";
        my $embedstrings = h->embed_string($query, $id, $embedstyle, params);
        
        my $p = {q => $query,
                 facets => $facets,
                 limit => h->config->{store}->{maximum_page_size}};
        $p->{'sort'} = $sruSort if $sruSort ne "";

        my $hits = h->search_publication($p);     
     
        my $dochits = h->search_publication({
        	q => $rawquery.$publyearquery,
        	limit => 1,
        	facets => {documentType => {terms => {field => 'documentType', size => 30}}},
        });
        
        my $yearhits = h->search_publication({
        	q => $rawquery.$doctypequery,
        	limit => 1,
        	facets => {year => {terms => {field => 'publishingYear', size => 100, order => 'reverse_term'}}},
        });
        
        $hits->{dochits} = $dochits;
        $hits->{yearhits} = $yearhits;
        $hits->{sruquery} = $sruSort;
        $hits->{embedstrings} = $embedstrings;
        
        my $titleName;
        $titleName .= $personInfo->{personTitle}." " if $personInfo->{personTitle};
        $titleName .= $personInfo->{givenName}." " if $personInfo->{givenName};
        $titleName .= $personInfo->{surname}." " if $personInfo->{surname};
        
        if($titleName){
        	$hits->{personPageTitle} = "Publications " . $titleName;
        }        
        
        $hits->{teststring} = request->params;
        
        my $marked = session 'marked';
        $marked ||= [];
        $hits->{marked} = @$marked;

        $hits->{style} = $style ||= $personStyle ||= "ama";
        
        if($fmt){
        	h->export_publication( $hits, $fmt );
        }
        else {
        	template $tmpl, $hits;
        }
};

get qr{/person/$} => sub {
    forward '/';
};

get qr{/person$} => sub {
    forward '/';
};

1;
