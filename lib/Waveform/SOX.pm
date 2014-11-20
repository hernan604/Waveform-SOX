package Waveform::SOX;
use Waveform::SOX::Bucket;
use strict;
use warnings;
use Moo;
use Try::Tiny;

use 5.008_005;
our $VERSION = '0.01';

has waveform => ( is => 'rw' );
has width => ( is => 'rw', default => sub { 1000 } );

before 'create' => sub {
    my $self = shift;
    $self->waveform(undef);
};

sub create {
    my $self       = shift;
    my $music_path = shift;
    return 0 if !-e $music_path or !-f $music_path;
    $music_path = $self->esc_chars( $music_path );
    my $sox_output = `sox $music_path -t raw -r 4000 -c 1 -L -`;
    return 0 if ! $sox_output;
    my @bytes   = unpack( 's*', $sox_output );
    my $buckets = [];
    my $bucket_size = int( ( scalar @bytes - 1 ) / $self->width + 0.5 ) + 1;

    for ( 0 .. $#bytes ) {
        my $byte  = $bytes[$_];
        my $index = int( $_ / $bucket_size );
        if ( $index < $self->width ) {
            $buckets->[$index] //= Waveform::SOX::Bucket->new;
            $buckets->[$index]->add($byte);
        }
    }
    my $peak = 0;
    for (@$buckets) {
        $peak =
          ( $_->peak > $peak )
          ? $_->peak
          : $peak;
    }
    $peak = $peak / 65535.0;

    my @waveform_data = map {
        my $bucket = $_;
        map {
            my $i   = $_;
            my $res;
            try {
                $res = $i / 65535 / $peak;
            } catch { 
                $res = 0 
            };
            $res;
          } ( $bucket->min, $bucket->max )
    } @$buckets;

    my @js_waveform_data = join ",", map { $self->each_slice( 3, $_ ); } map {
        my $f = $_;
        sprintf( "%.2f", $f );
    } @waveform_data;

    $self->waveform( @js_waveform_data );
    $self;
}

sub each_slice {
    my $self = shift;
    my $n    = shift;
    while ( my @next_n = splice @_, 0, $n ) {
        return join q{,}, @next_n;
    }
}

sub esc_chars {
    my $self = shift;
    my $filepath = shift;
    # =FROM= http://www.slac.stanford.edu/slac/www/resource/how-to-use/cgi-rexx/cgi-esc.html
    # will change, for example, a!!a to a\!\!a
    $filepath =~ s/([;<>\*\|`&\$!#\(\)\[\]\{\}:'"])/\\$1/g;
    return $filepath;
}

1;

__END__

=encoding utf-8

=head1 NAME

Waveform::SOX - Creates waveform data points to be used in canvas

=head1 SYNOPSIS

  use Waveform::SOX;
  my $wave = Waveform::SOX->new;
  my $audio_file = '/music/some.mp3';
  $wave->create( $audio_file );
  print $wave->waveform;

=head1 DESCRIPTION

Waveform::SOX is

=head1 AUTHOR

Hernan Lopes E<lt>hernanlopes@gmail.comE<gt>

=head1 CREDITS

This is a perl clone of the following software:

  https://github.com/aalin/canvas_waveform (ruby)

which derives from:
    
  http://github.com/rjp/cdcover/blob/master/cdcover.rb

=head1 COPYRIGHT

Copyright 2014- Hernan Lopes

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
