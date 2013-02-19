package Catmandu::Fix::publication_to_epicur;

use Catmandu::Sane;
use Moo;

sub fix {
    my ($self, $pub) = @_;
	my $epicur = {
		urn => $pub->{urn},
		_id => $pub->{_id},
	};
	
	$epicur;
	
}

1;
