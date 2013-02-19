package Catmandu::Fix::add_contributor_info;

use Catmandu::Sane;
use Moo;

sub fix {
    my ( $self, $pub ) = @_;
        
    if ( $pub->{author} ) {
        $pub->{first_author} = ref $pub->{author} eq 'ARRAY' ? $pub->{author}->[0]->{fullName} : $pub->{author}->{fullName};
        $pub->{last_author} = ref $pub->{author} eq 'ARRAY' ? $pub->{author}->[-1]->{fullName} : $pub->{author}->{fullName};
    }
    
    if ( $pub->{editor} ) {
        $pub->{first_editor} = ref $pub->{editor} eq 'ARRAY' ? $pub->{editor}->[0]->{fullName} : $pub->{editor}->{fullName};
        $pub->{last_author} = ref $pub->{editor} eq 'ARRAY' ? $pub->{editor}->[-1]->{fullName} : $pub->{editor}->{fullName};
    }

    $pub;
}

1;
