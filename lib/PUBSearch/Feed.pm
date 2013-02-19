package PUBSearch::Feed;

use lib qw(/srv/www/sbcat/lib);

use Catmandu::Sane;
use Catmandu::Fix qw(publication_to_dc);
use Dancer qw(:syntax);
use DateTime;
use XML::RSS;
use Encode;
use PUBSearch::Helper;

get qr{/feed/(hourly|daily|weekly|monthly)} => sub {
    state $fix = Catmandu::Fix->new(fixes => ['publication_to_dc()']);

    my ($period) = splat;

    my $now = DateTime->now;

    given ($period) {
        when ('hourly')  { $now->truncate(to => 'hour') }
        when ('daily')   { $now->truncate(to => 'day') }
        when ('weekly')  { $now->truncate(to => 'week') }
        when ('monthly') { $now->truncate(to => 'month') }
    }

    my $p;
    my $q = params->{'q'} ||= 'submissionStatus exact public';
    $p = {
	q => $q . ' AND dateLastChanged > '. $now->strftime('"%F %H:%M:00"'),
    	start => 0,
	limit => params->{'limit'} ||= h->config->{store}->{default_page_size},
    };

    my $rss = XML::RSS->new;

    $rss->channel(
        link => h->host,
        title => h->config->{app},
        description => h->config->{institution}->{name_eng}." ".h->config->{app},
        syn => {
            updatePeriod => $period,
            updateFrequency => "1",
            updateBase => "2000-01-01T00:00+00:00",
        }
    );
    my $hits = h->search_publication($p);
    $hits->each(sub {
        my $hit = $_[0];
	
	if ($hit->{_id} && $hit->{mainTitle}) {
           $rss->add_item(
              link  => h->host . "/publication/$hit->{_id}",
              title => $hit->{mainTitle},
              dc    => $fix->fix($hit),
           ); 
	}
    });

    content_type 'xhtml';#'application/xml+rss';
    return $rss->as_string;
};

1;
