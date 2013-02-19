package Catmandu::Fix::clean_department_info;

use Catmandu::Sane;
use Moo;

sub fix {
	my ( $self, $pub ) = @_;
	my $dep = $pub->{department};
	
	foreach (@$dep) {
		delete $_->{oId} if $_->{oId};
		delete $_->{type} if $_->{type};
		
		#ref $pub->{author} eq 'ARRAY' ? $pub->{author}->[0]->{fullName} : $pub->{author}->{fullName};
		if ($dep->{name}->[0]) {
			$dep->{orgName} = $dep->{name}->[0]->{text};
			delete $dep->{name};
		}
	}
	
	$pub;
}

1;