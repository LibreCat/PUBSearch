package Catmandu::Fix::publication_to_public;

use Catmandu::Sane;
use Moo;
use Dancer qw(:syntax config);

sub fix {
    my ($self, $pub) = @_;
    
    if (my $authors = $pub->{author}) {
    	foreach my $auth (@$authors) {
    		delete $auth->{luLdapId};
    		delete $auth->{oId};
    		delete $auth->{type};
		delete $auth->{citationStyle};
		delete $auth->{sortDirection};
    	}
    }

    if (my $editors = $pub->{editor}) {
        foreach my $ed (@$editors) {
                delete $ed->{luLdapId};
                delete $ed->{oId};
                delete $ed->{type};
		delete $ed->{citationStyle};
                delete $ed->{sortDirection};
        }
    }

    
    if ($pub->{language}) {
    	$pub->{language} = $pub->{language}->{name};
    }

    foreach ( qw(creator promoter message doiInfo oId file type project conference) ) {
	delete $pub->{$_};
    }    
	
    if ($pub->{department}) {
	delete $_->{oId};
	delete $_->{type}->{oId};
    }
	
    $pub;
}

1;
