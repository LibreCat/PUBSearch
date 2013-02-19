package Catmandu::Fix::clean_contributor_info;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
    my $au = $pub->{author};
    
    # authors    
    if ( $pub->{author} ) {
        $pub->{first_author} = ref $pub->{author} eq 'ARRAY' ? $pub->{author}->[0]->{fullName} : $pub->{author}->{fullName};
        $pub->{last_author} = ref $pub->{author} eq 'ARRAY' ? $pub->{author}->[-1]->{fullName} : $pub->{author}->{fullName};
    }

	foreach (@$au) {
		delete $_->{luLdapId} if $_->{luLdapId};
		delete $_->{oId} if $_->{oId};
		
		if ($_->{type}->{typeName} && $_->{type}->{typeName} eq 'luAuthor') {
			$_->{unibi} = 1;
			delete $_->{type};
		}
		
	}

	# editors
	my $ed = $pub->{editor};
	foreach (@$ed) {
		delete $_->{luLdapId};
		delete $_->{oId};
		
		if ($_->{type}->{typeName} && $_->{type}->{typeName} eq 'luAuthor') {
			$_->{unibi} = 1;
			delete $_->{type};
		}
	}

    $pub;
}

1;
