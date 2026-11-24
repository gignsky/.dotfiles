# Column & Coin's Fastmail account, added to the same Thunderbird profile as
# the WorkMail account in ./thunderbird.nix and the Gmail accounts in
# ./thunderbird-gmail.nix.
#
# Authentication is OAuth2, the same as Gmail. Thunderbird ships a built-in
# OAuth2 client for Fastmail (OAuth2Providers.sys.mjs maps imap., smtp.,
# carddav. and caldav.fastmail.com to it), so there is no app password and no
# sops secret: on first launch Thunderbird opens a Fastmail sign-in window,
# you sign in and press Allow, and Thunderbird stores the tokens itself. One
# grant covers mail, contacts and calendars.
#
# `flavor = "fastmail.com"` makes home-manager's accounts.email module fill in
# the servers: IMAP imap.fastmail.com:993 and SMTP smtp.fastmail.com:465, both
# implicit TLS, which is what Fastmail documents. Unlike WorkMail, Fastmail's
# IMAP advertises SPECIAL-USE, so Thunderbird finds Sent/Drafts/Trash itself
# and none of the folder wiring in thunderbird.nix is needed.
#
# Catch-all domains: countthecoin.com, columnandcoin.com, column-and-coin.com
# and coinandcolumn.com deliver into this one account, each filed into its own
# folder by a Fastmail rule. Those folders are made server side, so they are
# not guaranteed to be IMAP-subscribed; subscriptions are switched off below
# so Thunderbird lists every folder the server has. The identity is marked
# catch-all for all five domains, so a reply to mail sent to e.g.
# hello@columnandcoin.com goes out from that same address.
{
  config,
  lib,
  ...
}:
let
  profileName = "gig";

  address = "maxwell@countthecoin.us";
  realName = "Maxwell Rupp";

  # Every domain that lands in this mailbox, primary first.
  domains = [
    "countthecoin.us"
    "countthecoin.com"
    "columnandcoin.com"
    "column-and-coin.com"
    "coinandcolumn.com"
  ];
in
{
  accounts.email.accounts.countthecoin = {
    inherit address realName;
    flavor = "fastmail.com";

    # OAuth2 for both directions (Thunderbird authMethod 10).
    imap.authentication = "xoauth2";
    smtp.authentication = "xoauth2";

    thunderbird = {
      enable = true;
      profiles = [ profileName ];

      settings = id: {
        # Show every server folder, subscribed or not, so the per-domain
        # catch-all folders appear without a manual subscribe.
        "mail.server.server_${id}.using_subscription" = false;
        "mail.server.server_${id}.offline_download" = true;
        "mail.server.server_${id}.check_new_mail" = true;
        "mail.server.server_${id}.check_time" = 5;
      };

      perIdentitySettings = id: {
        # Reply from whichever address a message was actually sent to, for
        # any address at any of the Column & Coin domains.
        "mail.identity.id_${id}.catchAll" = true;
        "mail.identity.id_${id}.catchAllHint" = lib.concatMapStringsSep ", " (d: "*@${d}") domains;
      };
    };
  };

  # Fastmail's personal address book over CardDAV, under the same OAuth2 grant
  # (Fastmail documents the path as /dav/addressbooks/user/<address>/Default).
  # Calendars are left out on purpose: Fastmail calendar collections have
  # opaque ids, so one is added from Thunderbird's "New calendar > On the
  # network" with https://caldav.fastmail.com/ rather than guessed here.
  accounts.contact = {
    # Required by home-manager once any contact account exists; only local
    # (filesystem) address books would write here.
    basePath = lib.mkDefault "${config.xdg.dataHome}/contacts";

    accounts.countthecoin = {
      remote = {
        type = "carddav";
        url = "https://carddav.fastmail.com/dav/addressbooks/user/${address}/Default";
        userName = address;
      };
      thunderbird = {
        enable = true;
        profiles = [ profileName ];
      };
    };
  };
}
