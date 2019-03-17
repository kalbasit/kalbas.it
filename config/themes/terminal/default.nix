{ config, lib, ... }:

with lib;

{
  config = mkIf (config.theme == "terminal") {
    layoutDir = [ ./layouts ];

    params = {
      contentTypeName = "post";
      themeColor = "orange";
      showMenuItems = 3;
    };

    languages = {
      en = {
        title = "kalbasit";
        subtitle = "Wael Nasreddine";
        keywords = "";
        menuMore = "Show more";
        readMore = "Read more";
        readOtherPosts = "Read other posts";
        params = {
          logo = {
            logoText = "λ kalbas.it";
            logoHomeLink = "/";
          };
        };
        menu = {
          main = [
            {
              identifier = "about";
              name = "About";
              url = "/about";
            }
          ];
        };
      };
    };
  };
}
