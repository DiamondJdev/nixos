{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "10x50";
        origin = "top-right";
        corner_radius = 10;
        transparency = 10;
        frame_width = 1;
        font = "JetBrains Mono 10";
      };
      urgency_normal = {
        timeout = 10;
      };
    };
  };
}
