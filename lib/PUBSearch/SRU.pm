package PUBSearch::SRU;

# a slight modification of "package Dancer::Plugin::Catmandu::SRU"

our $VERSION = '0.01';

use Catmandu::Sane;
use Dancer::Plugin;
use PUBSearch::Helper;
use Dancer qw(:syntax);
use Catmandu;
use Catmandu::Util qw(:all);
use Catmandu::Fix qw(MODS_mapping clean_xml.pm);
use Catmandu::Exporter::Template;
use Catmandu::Store::ElasticSearch;
use SRU::Request;
use SRU::Response;


sub sru_provider {
    my ($path) = @_;
    Catmandu->load;
    my $conf = Catmandu->config;
    my $setting = $conf->{store}{SRU};
	my $default_record_schema = $setting->{default_record_schema};

    my $record_schemas = $setting->{record_schemas};

    my $record_schema_map = {};
    for my $schema (@$record_schemas) {
        $schema = {%$schema};
        my $identifier = $schema->{identifier};
        my $name = $schema->{name};
        if (my $fix = $schema->{fix}) {
            $schema->{fix} = Catmandu::Fix->new(fixes => $fix);
        }
        $record_schema_map->{$identifier} = $schema;
        $record_schema_map->{$name} = $schema;
    }
    
	my $store = Catmandu::Store::ElasticSearch->new( $conf->{store}{search}{options} );
	my $bag   = $store->bag('publicationItem');
    
    my $default_limit = $bag->default_limit;
    my $maximum_limit = $bag->maximum_limit;

    my $database_info = "";
    if ($setting->{title} || $setting->{description}) {
        $database_info .= qq(<databaseInfo>\n);
        for my $key (qw(title description)) {
            $database_info .= qq(<$key lang="en" primary="true">$setting->{$key}</$key>\n) if $setting->{$key};
        }
        $database_info .= qq(</databaseInfo>);
    }

    my $index_info = "";
    if ($bag->can('cql_mapping') and my $indexes = $bag->cql_mapping->{indexes}) { # TODO all Searchable should have cql_mapping
        $index_info .= qq(<indexInfo>\n);
        for my $key (keys %$indexes) {
            my $title = $indexes->{$key}{title} || $key;
            $index_info .= qq(<index><title>$title</title><map><name>$key</name></map></index>\n);
        }
        $index_info .= qq(</indexInfo>);
    }

    my $schema_info = qq(<schemaInfo>\n);
    for my $schema (@$record_schemas) {
        my $title = $schema->{title} || $schema->{name};
        $schema_info .= qq(<schema name="$schema->{name}" identifier="$schema->{identifier}"><title>$title</title></schema>\n);
    }
    $schema_info .= qq(</schemaInfo>);

    my $config_info = qq(<configInfo>\n);
    $config_info .= qq(<default type="numberOfRecords">$default_limit</default>\n);
    $config_info .= qq(<setting type="maximumRecords">$maximum_limit</setting>\n);
    $config_info .= qq(</configInfo>);

    get $path => sub {
        content_type 'xml';

        my $params = params('query');

        given ($params->{operation} // 'explain') {
            when ('explain') {
                my $request  = SRU::Request::Explain->new(%$params);
                my $response = SRU::Response->newFromRequest($request);

                my $transport   = request->scheme;
                my $database    = substr request->path, 1;
                my $host        = h->host; #$host =~ s/:.+//;
                #my $port        = request->port;
                $response->record(SRU::Response::Record->new(
                    recordSchema => 'http://explain.z3950.org/dtd/2.1/',
                    recordData   => <<XML,
<explain xmlns="http://explain.z3950.org/dtd/2.1/">
<serverInfo protocol="SRU" method="GET" transport="$transport">
<host>$host</host>
<database>$database</database>
</serverInfo>
$database_info
$index_info
$schema_info
$config_info
</explain>
XML
                ));
                return $response->asXML;
            }
            when ('searchRetrieve') {
                my $request  = SRU::Request::SearchRetrieve->new(%$params);
                my $response = SRU::Response->newFromRequest($request);

                my $schema = $record_schema_map->{$request->recordSchema || $default_record_schema};
                my $identifier = $schema->{identifier};
                my $fix = $schema->{fix};
                my $template = $schema->{template};
                my $layout = $schema->{layout};
                #my $cql = $params->{query};
                #if ($setting->{filter}) {
                #    $cql = "($setting->{filter}) AND ($cql)";
                #}
				my @cql;
				push @cql, "($setting->{filter})" if $setting->{filter};
				push @cql, "($params->{query})" if ($params->{query} && $params->{query} ne '');
			
                my $first = $request->startRecord || 1;
                my $limit = $request->maximumRecords || $default_limit;
                my $hits = eval {
                    $bag->search(
                        cql_query    => join(' AND ', @cql),
                        sru_sortkeys => $request->sortKeys,
                        limit        => $limit,
                        start        => $first - 1,
                    );
                } or do {
                    my $e = $@;
                    if ($e =~ /^cql error/) {
                        $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(10));
                        return $response->asXML;
                    }
                    die $e;
                };
				my $fixer = Catmandu::Fix->new (fixes => [
									'MODS_mapping()',
									'clean_xml()', 
									]);
                $hits->each(sub {
                    my $data = $fixer->fix($_[0]);
                    my $metadata = template $template, $data;
                    #my $exporter = Catmandu::Exporter::Template->new(
                    #    template => $template,
                    #    file     => \$metadata,
                   #     fix      => $fix,
                   # );
                    #$exporter->add($data);
                    #$exporter->commit;
                    $response->addRecord(SRU::Response::Record->new(
                        recordSchema => $identifier,
                        recordData   => $metadata,
                    ));
                });
                $response->numberOfRecords($hits->total);
                return $response->asXML;
            }
            default {
                my $request  = SRU::Request::Explain->new(%$params);
                my $response = SRU::Response->newFromRequest($request);
                $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(6));
                return $response->asXML;
            }
        }
    };
}

register sru_provider => \&sru_provider;

register_plugin;

1;
