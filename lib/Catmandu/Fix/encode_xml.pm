package Catmandu::Fix::encode_xml;

use Catmandu::Sane;
use Moo;

use MKDoc::XML::Encode;

sub fix {
    my ( $self, $pub ) = @_;

    if (my $cit = $pub->{citations}) {
        foreach (keys %$cit) {
                $pub->{citations}->{$_} = MKDoc::XML::Encode->process($cit->{$_});
        }
    }

    $pub;
}

1;

