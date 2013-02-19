package Catmandu::Exporter::Cite;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:array :string);
use Moo;

with 'Catmandu::Exporter';

has style => (is => 'ro', builder => 'default_style');
has numbered => (is => 'ro', lazy => 1, builder => '_build_numbered');

sub default_style { 'ama' }

sub _build_numbered {
    my ($self) = @_;
    state $styles = do {
        my $list = Catmandu->config->{publication_styles};
        my $hash = {};
        for my $style (@$list) {
            $hash->{$style->{value}} = $style->{numbered} ? 1 : 0;
        }
        $hash;
    };
    $styles->{$self->style};
}

sub add {
    my ($self, $pub) = @_;
    if (my $cite = $self->_cite($pub)) {
        $self->_add_cite($cite);
    }
}

sub _add_cite {
    my ($self, $cite) = @_;
    $self->fh->print($cite);
    $self->fh->print("\n");
}

sub _cite {
    my ($self, $pub) = @_;
    if (my $cite = $pub->{citation}{$self->style}) {
    	# remove tabs, newlines
        $cite =~ s/[\t\r\n]+//go;
        return $self->_renumber($cite) if $self->numbered;
        return $cite;
    }
    return;
}

sub _renumber {
    my ($self, $cite) = @_;
    my $n = $self->count + 1;
    $cite =~ s/"csl-left-margin">1/"csl-left-margin">$n/;
    $cite;
}

1;
