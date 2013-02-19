package Catmandu::Fix::clean_xml;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
    foreach (@{ $pub->{abstract} }) {
	$_->{text} =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;
    }

    $pub;
}

1;
