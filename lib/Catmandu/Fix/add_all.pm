package Catmandu::Fix::add_all;

use Catmandu::Sane;
use Catmandu::Util qw(is_string);
use Moo;

sub fix {
    my ($self, $pub) = @_;

    if (my $val = $pub->{conference}) {
        $val->{_all} = join ' ', grep { is_string($_) }
            $val->{name},
            $val->{organizer},
            $val->{location};
    }

    if (my $val = $pub->{project}) {
        for my $v (@$val) {
            $v->{_all} = join ' ', grep { is_string($_) }
                $v->{_id},
                $v->{title},
                $v->{abstract},
                $v->{eu_id},
                $v->{eu_call_id},
                $v->{eu_acronym},
                $v->{eu_framework_programme};
        }
    }

    $pub;
}

1;
