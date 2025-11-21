{
  sops.secrets."opencode-auth-json" = {
    mode = "600";
    path = "/home/gig/.local/share/opencode/auth.json";
  };
}
