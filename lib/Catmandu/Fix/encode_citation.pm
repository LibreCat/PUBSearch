package Catmandu::Fix::encode_citation;

use Catmandu::Sane;
use Moo;

use HTML::Entities;

sub fix {
    my ( $self, $pub ) = @_;
    
    if (my $cit = $pub->{citations}) {
    	foreach (keys %$cit) {
    		$pub->{citations}->{$_} = HTML::Entities::decode_entities($cit->{$_});
    	}
    }
    
    $pub;
}

1;