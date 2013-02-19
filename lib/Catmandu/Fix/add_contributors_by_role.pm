package Catmandu::Fix::add_contributors_by_role;

use Catmandu::Sane;
use Catmandu::Util qw(array_group_by);
use Moo;

sub fix {
    my ($self, $pub) = @_;

    if ($pub->{contributor}) {
        my $roles = array_group_by($pub->{contributor}, 'role');
        for my $role (keys %$roles) {
            my $people = $roles->{$role};
            $pub->{$role} = [map {
                my $p = {%$_};
                delete $p->{role};
                $p;
            } @$people];
        }
    }

    if ($pub->{author}) {
        $pub->{first_author} = $pub->{author}->[0];
    }

    $pub;
}

1;
