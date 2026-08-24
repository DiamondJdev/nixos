{ inputs, pkgs, ... }: {
  services.dunst = {
    enable = true;

    settings = {
      global = {
        # Display
        monitor = 0;
        follow = "mouse";

        #Geometry
        width = 300;
        height = 300;

      };
    };
  };
}
