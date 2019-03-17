{ config, lib, ... }:

with lib;

{
  config = mkIf (config.theme == "geo") {
    layoutDir = [ ./layouts ];

    params = {
      # Render the rotating globe in the sidebar
      showglobe = true;

      # Include favicon
      favicon = "favicon.ico";

      # Google Analytics
      analytics = config.googleAnalytics;

      # Email (optional)
      email = config.authorEmail;

      # Header Title for the main page
      header = "What I'm Thinking";

      # Sidebar profile picture
      profilepic = "img/me.jpg";

      # Title/subtitle for the sidebar
      title = config.author;
      subtitle = config.tagLine;

      # Social buttons for sidebar
      # Each of these are optional
      socialButtons = [
        {
          faicon = "github";
          url = "https://github.com/kalbasit";
        }

        {
          faicon = "twitter";
          url = "https://twitter.com/ylcodes";
        }

        {
          faicon = "linkedin";
          url = "https://www.linkedin.com/in/kalbasit";
        }
      ];

      # Nav links below the profile picture
      navLinks = [
        {
          name = "About";
          url = "about/";
        }

        {
          name = "Blog";
          url = "post/";
        }

        {
          name = "Tags";
          url = "tags/";
        }

        {
          name = "Tutorials";
          url = "tutorial/";
        }
      ];
    };
  };
}
