{ inputs, pkgs, ... }: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "10x50";
        origin = "top-right";
        transparency = 10;
        frame_width = 1;
        font = "JetBrains Mono 10";
      };
    };
  };
}
