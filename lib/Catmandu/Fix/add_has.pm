package Catmandu::Fix::add_has;

use Catmandu::Sane;
use Catmandu::Util qw(array_any);
use Moo;

sub fix {
    my ($self, $pub) = @_;

    if ($pub->{file} && @{$pub->{file}}) {
        $pub->{has_file} = 1;
        if (array_any($pub->{file}, sub { $_[0]->{access} eq 'open' })) {
            $pub->{has_open_access_file} = 1;
        }
        if (array_any($pub->{file}, sub { $_[0]->{access} eq 'restricted' })) {
            $pub->{has_restricted_access_file} = 1;
        }
    }

    $pub;
}

1;
