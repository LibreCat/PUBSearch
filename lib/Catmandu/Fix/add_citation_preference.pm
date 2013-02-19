package Catmandu::Fix::add_citation_preference;

use Catmandu::Sane;
use Moo;

sub fix {
	
    my ( $self, $data ) = @_;
 
 	if ($data->{citationStyle} && $data->{sortDirection}) {
 		$data->{stylePreference} = $data->{citationStyle} . "." . lc $data->{sortDirection};
 		delete $data->{citationStyle};
 		delete $data->{sortDirection};
 	} elsif (!$data->{citationStyle} && $data->{sortDirection}) {
 		$data->{stylePreference} = "pub." . lc $data->{sortDirection};
 		delete $data->{sortDirection};
 	}
 	
 	
	$data;    
}

1;