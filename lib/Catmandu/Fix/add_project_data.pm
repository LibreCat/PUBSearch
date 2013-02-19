package Catmandu::Fix::add_project_data;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu qw(store);
use Moo;

my $projects = store('search')->bag('project');

sub fix {
    my ($self, $pub) = @_;

    if (my $list = $pub->{project}) {
        for (my $i = 0; $i < @$list; $i++) {
            if (my $project = $projects->get($list->[$i]->{_id})) {
                $list->[$i] = $project;
            }
        }
    }

    $pub;
}

1;
