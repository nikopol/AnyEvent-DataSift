package AnyEvent::DataSift;

use 5.010;
use strict;
use warnings;

use Carp;
use AnyEvent::HTTP;
use AnyEvent::DataSift::Stream::HTTP;
use JSON;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self = {
		host      => 'datasift.com',
		port      => 80,
		username  => undef,
		apikey    => undef,
		timeout   => 300,   
		useragent => 'DataSiftPerlConsumer/'.$VERSION,
		@_
	};

	croak 'username required'   unless $self->{username};
	croak 'apikey required'     unless $self->{apikey};

	bless $self, $class;
}

sub REST {
	my $self = shift;
	my $api  = shift;
	my $params = {
		username => $self->{username},
		api_key  => $self->{apikey},
		@_,
	};
	my $on_data  = delete($params->{on_data}) || sub{};
	my $on_error = delete($params->{on_error}) || sub{};
	my $method   = delete($params->{method}) || 'POST';
	http_request 
		$method  => 'http://api.'.$self->{host}.'/'.$api,
		%$params,
		sub {
			my( $data, $headers ) = @_;
			if ($headers->{Status} =~ /^2/) {
				$on_data->( decode_json $data );
			} else {
				$on_error->( $headers->{Status}, $headers->{Reason} );
			}
		};
	$self;
}

sub balance     { shift->REST( balance => @_ ) };
sub validate    { shift->REST( validate => @_ ) };
sub compile     { shift->REST( compile => @_ ) };
sub dpu         { shift->REST( dpu => @_ ) };
sub usage       { shift->REST( usage => @_ ) };
sub REST_stream { shift->REST( stream => @_ ) };

sub recording               { shift->REST( recording => @_ ) };
sub delete_recording        { shift->REST( 'recording/delete' => @_ ) };
sub export_recording        { shift->REST( 'recording/export' => @_ ) };
sub delete_export_recording { shift->REST( 'recording/export/delete' => @_ ) };
sub start_export_recording  { shift->REST( 'recording/export/start' => @_ ) };
sub schedule_recording      { shift->REST( 'recording/schedule' => @_ ) };
sub update_recording        { shift->REST( 'recording/update' => @_ ) };

sub HTTP_stream {
	my $self = shift;
	AnyEvent::DataSift::Stream::HTTP->new(
		host      => 'stream.'.$self->{host},
		port      => $self->{port},
		username  => $self->{username},
		apikey    => $self->{apikey},
		timeout   => $self->{timeout},
		useragent => $self->{useragent},
		@_
	);
}

1;
__END__
