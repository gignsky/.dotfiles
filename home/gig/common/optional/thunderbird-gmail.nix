# Personal Gmail accounts, added to the same Thunderbird profile as the
# WorkMail account configured in ./thunderbird.nix.
#
# Unlike WorkMail, Gmail is authenticated with OAuth2 (Thunderbird ships a
# built-in OAuth2 client for well-known providers, so no app password or
# secret is needed). The `flavor = "gmail.com"` setting makes home-manager's
# accounts.email module fill in the IMAP/SMTP hosts and ports, and makes the
# thunderbird module default both authMethod settings to 10 (OAuth2) and set
# is_gmail = true so Thunderbird auto-detects the special folders (Gmail's
# IMAP server advertises SPECIAL-USE, unlike WorkMail, so none of the manual
# folder wiring in thunderbird.nix is needed here).
#
# There is therefore nothing to seed: on first launch Thunderbird prompts for
# a browser-based Google sign-in per account, then stores the resulting
# OAuth2 tokens itself.
let
  profileName = "gig";
  realName = "Maxwell Rupp";

  mkGmailAccount = address: {
    inherit address realName;
    flavor = "gmail.com";

    thunderbird = {
      enable = true;
      profiles = [ profileName ];
    };
  };
in
{
  accounts.email.accounts = {
    gignsky = mkGmailAccount "gignsky@gmail.com";
    cash342002 = mkGmailAccount "cash342002@gmail.com";
    maxwellcrupp = mkGmailAccount "maxwellc.rupp@gmail.com";
  };
}
