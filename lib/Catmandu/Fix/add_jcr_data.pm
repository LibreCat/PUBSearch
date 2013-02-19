package Catmandu::Fix::add_jcr_data;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu qw(store);
use Moo;

my $jcr = store('authority')->bag('jcr');

$jcr->collection->ensure_index({issn => 1, year => 1}, {safe => 1});

sub fix {
    my ($self, $pub) = @_;
    my $issn = $pub->{issn};
    my $year = $pub->{year};

    if ($issn && $year) {
        if (my @data = $jcr->collection->find({issn => {'$in' => $issn}, year => int($year)})->all) {
            for my $key (qw(eigenfactor immediacy_index impact_factor impact_factor_5year total_cites)) {
                my ($val) = sort { $b <=> $a } map { $_->{$key} } grep { is_number($_->{$key}) } @data;
                $pub->{jcr}{$key} = $val if defined $val;
            }

            my ($val) = sort grep { is_string($_) }
                            map { values %{$_->{category_quartile}} }
                                grep { is_hash_ref($_->{category_quartile}) } @data;
            if (defined $val) {
                $pub->{jcr}{category_quartile} = $val;
            }
        }
        if (my @data = $jcr->collection->find({issn => {'$in' => $issn}, year => int($year) - 1})->all) {
            my ($val) = sort { $b <=> $a } map { $_->{impact_factor} } grep { is_number($_->{impact_factor}) } @data;
            $pub->{jcr}{prev_impact_factor} = $val if defined $val;

            ($val) = sort grep { is_string($_) }
                        map { values %{$_->{category_quartile}} }
                            grep { is_hash_ref($_->{category_quartile}) } @data;
            if (defined $val) {
                $pub->{jcr}{prev_category_quartile} = $val;
            }
        }
    }

    $pub;
}

1;
