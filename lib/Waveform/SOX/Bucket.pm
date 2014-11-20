package Waveform::SOX::Bucket;
use Moo;

has [qw|min max|] => ( is => "rw", default => sub { 0 } );

sub add {
    my $self  = shift;
    my $value = shift;
    $self->max($value) if $value > $self->max;
    $self->min($value) if $value < $self->min;
}

sub peak {
    my $self = shift;
    my $x    = abs $self->min;
    my $y    = abs $self->max;
    return ( $self->min, $self->max )[ abs $self->min < abs $self->max ];
}

1;
