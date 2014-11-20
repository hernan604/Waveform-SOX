use strict;
use Test::More;
use Waveform::SOX;

my $wave = Waveform::SOX->new;
$wave->create('./t/short.mp3');
ok( $wave->waveform->[0] =~ m#0.23,0.47,-0.67,0.60,-0.69,0.75,-0.41,0.19,-0.51,0.31,-0.50,0.30#, '' );

done_testing;
