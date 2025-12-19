{
  pkgs,
  ...
}:

{
  services.sstorytime = {
    enable = true;
    port = 3030;
    openFirewall = true;
    database.createLocally = true;
  };
}
