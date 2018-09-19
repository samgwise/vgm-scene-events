#! /usr/bin/env perl6
use v6.c;
use VGM::Scene::Events;
use Reaper::Control;
use Net::OSC::Message;

sub MAIN(Str :$reaper = 'localhost:9000', Str :$scene, Str :$generator) {
    my $reaper-control = reaper-listener( |split-host-port($reaper) );
    my $scene-config = load-scene-config($scene);

    my ($host, $port) = split-host-port($generator)<host port>;
    my $events-out = IO::Socket::Async.udp;
    react whenever sync-scene-events($reaper-control, $scene-config) {
        put .perl;
        $events-out.write-to:
            $host,
            $port,
            Net::OSC::Message.new(path => .<path>, args => |.<message>.grep( *.defined )).package
    }
}

sub split-host-port(Str $service) {
    given $service.split(/':'/) -> ($host, Int(Cool) $port) {
        %(
            :$host,
            :$port
        )
    }
}
