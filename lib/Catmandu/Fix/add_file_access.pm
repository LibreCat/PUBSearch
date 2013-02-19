package Catmandu::Fix::add_file_access;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
        
    if ( $pub->{file} ) {
        my $files = ref $pub->{file} eq 'ARRAY' ? $pub->{file} : [$pub->{file}];
        for my $f ( @$files ) {
            $f->{openAccess} = ($f->{accessLevel} &&  $f->{accessLevel} eq 'openAccess')
                   ? 1
                   : 0
                   ;
        }
    }

    $pub;
}

1;
