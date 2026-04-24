{ ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Conflict guard — PulseAudio daemon must not run alongside PipeWire.
  services.pulseaudio.enable = false;
}
