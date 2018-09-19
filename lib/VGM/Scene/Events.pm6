use v6.c;
unit class VGM::Scene::Events:ver<0.0.1>;
use Reaper::Control;
use JSON::Fast;

=begin pod

=head1 NAME

VGM::Scene::Events - Trigger events in sync with Reaper

=head1 SYNOPSIS

  use VGM::Scene::Events;

=head1 DESCRIPTION

VGM::Scene::Events is a module for triggering events in sync with Reaper playback.
Events are defined for specific videos in a JSON file.

=head1 AUTHOR

Sam Gillespie <samgwise@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Sam Gillespie

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

our sub load-scene-config(Str $path --> Map) is export {
    #= load a scene event configuration from a local file
    $path.IO.slurp.&from-json
}

our sub sync-scene-events(Reaper::Control::Listener $reaper, Map $scene --> Supply) is export {
    #= Creates a Supply which emits events from the Scene map according to time information received from Reaper.

    my @events = $scene<frameEvents>.sort( { $^a<delta> <=> $^b<delta> } );
    put "loaded { @events.elems } events";
    my atomicint $event-counter = 0;
    my $limit = @events.elems;

    my Supplier $scene-events .= new;
    $reaper.reaper-events.tap: {
        when Reaper::Control::Event::PlayTime {
            $scene-events.emit: @events[$event-counter⚛++] while ⚛$event-counter < $limit and @events[⚛$event-counter]<delta> <= .seconds
        }
        when Reaper::Control::Event::PlayState {
            $event-counter ⚛= 0
        }
    }

    $scene-events.Supply
}

