package PUBSearch::Mark;

use Catmandu::Sane;
use Catmandu qw(:load store export_to_string);
use Catmandu::Util qw(:is :array);
use Dancer qw(:syntax);
use Catmandu::Util;
use List::Util;
use DateTime;
use PUBSearch::Helper;


get '/marked' => sub {
	
    my $bag = Catmandu->store('search')->bag('publicationItem');
        
    my $hits;
    my $fmt = params->{fmt};
    my $marked = session 'marked';
    my $markedlist;
    if ($marked && @$marked) {
        foreach (@$marked){
        	my $q = "id=$_";
        	$hits = $bag->search(
        	  cql_query => $q,
        	  limit => h->config->{store}->{maximum_page_size},
        	  start => 0,
        	);
        	push @{$markedlist}, $hits->{hits}->[0];
        }
        
        $hits->{hits} = $markedlist;
        $hits->{total} = @$markedlist;
        $hits->{marked} = $marked;
    
    }
    
    if($fmt and $hits){
    	$hits->{style} = params->{style} ||= 'ama';
    	h->export_publication( $hits, $fmt );
    }
    else {
    	template 'marked', $hits;
    }
};

post '/marked/:id' => sub {
    my $id = param 'id';
    my $del = params->{'x-tunneled-method'};
    if($del){
    	my $marked = session 'marked';
    	if ($marked) {
			$marked = [ grep { $_ ne $id } @$marked ];
			session 'marked' => $marked;
		}
		content_type 'application/json';
		return to_json {
			ok => true,
			total => scalar @$marked,
		};
    }
    
    forward '/marked', {q => "id=$id"};
};

post '/marked' => sub {
	my $query;
	
	if(params->{q}){
		$query = params->{q};
	}
	
	else{
		$query .= "person=" . params->{id} if params->{id};
		
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
		
		if(params->{publicationtype} and ref params->{publicationtype} eq 'ARRAY'){
			my $tmpquery = "";
			foreach (@{params->{publicationtype}}){
				$tmpquery .= "documenttype=" . $_ . " OR ";
			}
			$tmpquery =~ s/ OR $//g;
			$query .= " AND (" . $tmpquery . ")";
		}
		elsif (params->{publicationtype} and ref params->{publicationtype} ne 'ARRAY'){
			$query .= " AND documenttype=". params->{publicationtype};
		}
		
		if(params->{publishingyear} and ref params->{publishingyear} eq 'ARRAY'){
			my $tmpquery = "";
			foreach (@{params->{publishingyear}}){
				$tmpquery .= "publishingyear=" . $_ . " OR ";
			}
			$tmpquery =~ s/ OR $//g;
			$query .= " AND (" . $tmpquery . ")";
		}
		elsif (params->{publishingyear} and ref params->{publishingyear} ne 'ARRAY'){
			$query .= " AND publishingyear=". params->{publishingyear};
		}
	}
    
	my $del = params->{'x-tunneled-method'};
	my $marked = session 'marked';
	$marked ||= [];
	
	if($del){
		if (session 'marked') {
			session 'marked' => [];
		}
		return to_json {
			ok => true,
			total => 0,
		};
	}
    
    
    if (@$marked == 500) {
    	content_type 'application/json';
        return to_json {
            ok => false,
            message => "the marked list has a limit of 500 records, remove some records first",
            total => scalar @$marked,
        };
    }
    params->{limit} = 500 - @$marked;

    my $hits = h->search_publication({q => $query, limit => h->config->{store}->{maximum_page_size}, start => 0});
    if ($hits->{total} > $hits->{limit} && @$marked == 500) {
        return to_json {
            ok => true,
            message => "the marked list has a limit of 500 records, only the first 500 records will be added",
            total => scalar @$marked,
        };
    }
    elsif($hits->{total}){
    	foreach (@{$hits->{hits}}){
    		my $id = $_->{_id};
    		push @$marked, $id unless array_includes($marked, $id);
    	}
    	session 'marked' => $marked;
    }
    content_type 'application/json';
    return to_json {
        ok => true,
        total => scalar @$marked,
    };
};

post '/reorder/:id/:newpos' => sub {
	forward '/reorder', {id => params->{id}, newpos => params->{newpos}};
};

post '/reorder' => sub {
	my $id = params->{id};
	my $newpos = params->{newpos};
	
	my $marked = session 'marked';
	$marked = [ grep { $_ ne $id } @$marked ];
	
	my @rest = splice (@$marked,$newpos);
	push @$marked, $id;
	push @$marked, @rest;
	
	session 'marked' => $marked;
	
};

1;
