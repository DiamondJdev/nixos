{ ... }:
{
  services.hyprpaper = {
    enable = true;

    settings = {
      preload = [
        "./rice/imgs/TF2.jpg"
      ];

      wallpaper = [
        {
          monitor = "";
          path = "./rice/imgs/TF2.jpg";
        }
      ];
    };
  };
}
