package Catmandu::Fix::publication_to_csv;

use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Moo;

my $VALUE_FIELDS = [qw(type title wos_id wos_type classification year date series_title
    volume issue issue_title edition article_type misc_type dissertation_type
    conference_type copyright_statement publication_status
    date_created date_updated date_submitted date_approved additional_info)];

my $ARRAY_FIELDS = [qw(alternative_title isbn issn abstract subject
    keyword language doi)];

my $JCR_FIELDS = [qw(eigenfactor immediacy_index impact_factor impact_factor_5year total_cites category_quartile
    prev_impact_factor prev_category_quartile)];

my $JOIN = ' ; ';

sub _add_contributors {
    my ($csv, $key, $val) = @_;
    $csv->{$key} = join $JOIN, map { $_->{name} } @$val;
    $csv->{"ugent_$key"} = join $JOIN, map { "$_->{name} ($_->{ugent_id}->[0])" } grep { $_->{ugent_id} } @$val;
}

sub fix {
    my ($self, $pub) = @_;

    my $csv = { id => $pub->{_id} };

    for my $key (@$VALUE_FIELDS) {
        $csv->{$key} = $pub->{$key};
    }

    my $val;

    for my $key (@$ARRAY_FIELDS) {
        if ($val = $pub->{$key}) {
            $csv->{$key} = join $JOIN, @$val;
        }
    }

    $csv->{reference} = h->reference($pub);

    if ($val = $pub->{contributor}) {
        my $roles = array_group_by($val, 'role');
        _add_contributors($csv, $_, $roles->{$_}) for keys %$roles;
        _add_contributors($csv, 'contributor', $val);
    }

    for my $key (qw(created_by last_reviewed_by)) {
        if ($val = $pub->{$key}) {
            $csv->{$key} = $val->{ugent_id} ? "$val->{name} ($val->{ugent_id}->[0])" : $val->{name};
        }
    }

    if ($val = $pub->{affiliation} and @$val) {
        $csv->{affiliation} = join $JOIN, map { $_->{ugent_id} } grep { $_->{ugent_id} } @$val;
    }

    if ($val = $pub->{publisher}) {
        $csv->{publisher_name} = $val->{name};
        $csv->{publisher_location} = $val->{location};
    }

    if ($val = $pub->{page}) {
        $csv->{page_count} = $val->{count};
        $csv->{page_first} = $val->{first};
        $csv->{page_last} = $val->{last};
    }

    if ($val = $pub->{parent}) {
        $csv->{parent_title} = $val->{title};
        $csv->{parent_short_title} = $val->{short_title};
    }

    if ($val = $pub->{conference}) {
        $csv->{conference_name} = $val->{name};
        $csv->{conference_organizer} = $val->{organizer};
        $csv->{conference_location} = $val->{location};
        $csv->{conference_start_date} = $val->{start_date};
        $csv->{conference_end_date} = $val->{end_date};
    }

    if ($val = $pub->{defense}) {
        $csv->{defense_date} = $val->{date};
        $csv->{defense_location} = $val->{location};
    }

    if ($val = $pub->{project}) {
        $csv->{project_id} = join $JOIN, map { $_->{_id} } @$val;
        $csv->{project_title} = join $JOIN, map { $_->{title} // "" } @$val;
        $csv->{project_abstract} = join $JOIN, map { $_->{abstract} // "" } @$val;
        $csv->{project_start_date} = join $JOIN, map { $_->{start_date} // "" } @$val;
        $csv->{project_end_date} = join $JOIN, map { $_->{end_date} // "" } @$val;
        $csv->{project_eu_id} = join $JOIN, map { $_->{eu_id} // "" } @$val;
        $csv->{project_eu_call_id} = join $JOIN, map { $_->{eu_call_id} // "" } @$val;
        $csv->{project_eu_acronym} = join $JOIN, map { $_->{eu_acronym} // "" } @$val;
    }

    if ($val = $pub->{jcr}) {
        for my $key (@$JCR_FIELDS) {
            $csv->{"jcr_$key"} = $val->{$key};
        }
    }

    $csv->{external} = $pub->{external} ? 'Y' : 'N';

    $csv->{has_file} = $pub->{file} && $pub->{file}->[0] ? 'Y' : 'N';

    $csv->{has_open_access_file} = $pub->{file} && array_any($pub->{file}, sub { $_[0]->{access} eq 'open' }) ? 'Y' : 'N';

    $csv;
}

1;
