{
  pkgs,
  lib,
  ...
}:
{
  # MAGEC Multi-Agent Platform - System Services
  # PostgreSQL + Redis for multi-agent memory and sessions

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;

    # pgvector extension for AI embeddings and semantic search
    extraPlugins = with pkgs.postgresql_16.pkgs; [
      pgvector
    ];

    authentication = lib.mkOverride 10 ''
      # Local connections for MAGEC
      local   magec       magec                               scram-sha-256
      host    magec       magec       127.0.0.1/32            scram-sha-256
      host    magec       magec       ::1/128                 scram-sha-256

      # Preserve existing PostgreSQL authentication rules
      local   all         all                                 peer
      host    all         all         127.0.0.1/32            scram-sha-256
      host    all         all         ::1/128                 scram-sha-256
    '';

    # Initialize MAGEC database and user
    initialScript = pkgs.writeText "magec-init.sql" ''
      -- Create MAGEC user and database
      DO $$ 
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'magec') THEN
          CREATE USER magec WITH PASSWORD 'magec_dev_password';
        END IF;
      END $$;

      CREATE DATABASE magec OWNER magec;

      -- Enable pgvector extension for semantic memory
      \c magec
      CREATE EXTENSION IF NOT EXISTS vector;

      -- Grant necessary permissions
      GRANT ALL PRIVILEGES ON DATABASE magec TO magec;
    '';

    settings = {
      # Load pgvector extension
      shared_preload_libraries = "vector";

      # Performance tuning for AI workloads
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "128MB";
      work_mem = "16MB";
    };
  };

  # Redis for session memory and fast caching
  services.redis.servers.magec = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";

    # Persistence for session recovery across restarts
    save = [
      [
        900
        1
      ] # After 15 min if at least 1 key changed
      [
        300
        10
      ] # After 5 min if at least 10 keys changed
      [
        60
        10000
      ] # After 60 sec if at least 10000 keys changed
    ];

    # Use AOF for better durability
    appendOnly = true;
    appendFsync = "everysec";
  };

  # Optional: Open firewall ports for remote access
  # Uncomment if you need to access MAGEC from other machines
  # networking.firewall.allowedTCPPorts = [ 8080 8081 ];

  # Ensure user has access to audio devices for voice processing
  users.users.gig.extraGroups = [ "audio" ];
}
