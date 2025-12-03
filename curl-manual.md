# The Complete curl Manual for System Administration and DNS Troubleshooting

## Table of Contents

1. [Introduction](#introduction)
2. [Basic curl Concepts](#basic-curl-concepts)
3. [DNS Troubleshooting with curl](#dns-troubleshooting-with-curl)
4. [HTTP/HTTPS Operations](#httphttps-operations)
5. [Authentication Methods](#authentication-methods)
6. [Data Transfer and File Operations](#data-transfer-and-file-operations)
7. [Advanced Networking](#advanced-networking)
8. [API Testing and Development](#api-testing-and-development)
9. [Debugging and Monitoring](#debugging-and-monitoring)
10. [Security and Certificates](#security-and-certificates)
11. [Performance Testing](#performance-testing)
12. [Automation and Scripting](#automation-and-scripting)
13. [Common Use Cases for Your Projects](#common-use-cases-for-your-projects)
14. [Troubleshooting Common Issues](#troubleshooting-common-issues)
15. [Best Practices](#best-practices)
16. [Quick Reference](#quick-reference)

---

## Introduction

curl is a command-line tool and library for transferring data with URLs. It supports numerous protocols including HTTP, HTTPS, FTP, SFTP, and many others. For system administrators and developers managing infrastructure like your NixOS configurations, Cloudflare domains, and containerized services, curl is an indispensable tool for testing, debugging, and automating network operations.

This manual focuses on practical applications relevant to your projects including DNS troubleshooting, API testing for services like Cloudflare, container health checks, and network debugging for your infrastructure spanning spacedock, memory-alpha, and other systems.

---

## Basic curl Concepts

### Core Syntax
```bash
curl [options] [URL]
```

### Essential Options
- `-v, --verbose`: Enable verbose mode for debugging
- `-s, --silent`: Silent mode (no progress bar or error messages)
- `-S, --show-error`: Show errors even in silent mode
- `-f, --fail`: Fail silently on server errors
- `-L, --location`: Follow redirects
- `-o, --output`: Write output to file
- `-O, --remote-name`: Use remote filename for local file

### Output Control
```bash
# Save to specific file
curl -o output.html https://example.com

# Use remote filename
curl -O https://example.com/file.zip

# Append to file
curl https://example.com >> log.txt

# Silent operation with error display
curl -sSL https://example.com
```

---

## DNS Troubleshooting with curl

### Basic DNS Resolution Testing

#### Test Basic Connectivity
```bash
# Test if a domain resolves and responds
curl -I https://gignsky.com

# Test with specific timeout
curl --connect-timeout 10 https://gignsky.com

# Test without following redirects
curl -I --max-redirs 0 https://gignsky.com
```

#### DNS Resolution Timing
```bash
# Show timing information including DNS lookup
curl -w "@-" -o /dev/null -s https://gignsky.com << 'EOF'
     time_namelookup:  %{time_namelookup}s\n
      time_connect:  %{time_connect}s\n
   time_appconnect:  %{time_appconnect}s\n
  time_pretransfer:  %{time_pretransfer}s\n
     time_redirect:  %{time_redirect}s\n
time_starttransfer:  %{time_starttransfer}s\n
                   ----------\n
        time_total:  %{time_total}s\n
EOF
```

#### Force Specific DNS Servers
```bash
# Use specific DNS server (bypass system DNS)
curl --dns-servers 1.1.1.1 https://example.com

# Use multiple DNS servers
curl --dns-servers 1.1.1.1,8.8.8.8 https://example.com

# Use Cloudflare DNS over HTTPS
curl --doh-url https://cloudflare-dns.com/dns-query https://example.com
```

### Advanced DNS Troubleshooting

#### Bypass DNS Resolution (Host Header Testing)
```bash
# Test direct IP connection with Host header
curl -H "Host: gignsky.com" http://104.21.45.167/

# Test multiple IPs for load balancing
for ip in 104.21.45.167 172.67.74.226; do
  echo "Testing IP: $ip"
  curl -H "Host: gignsky.com" -I http://$ip/
done
```

#### DNS-over-HTTPS (DoH) Testing
```bash
# Query DNS record via Cloudflare DoH
curl -H "accept: application/dns-json" \
  "https://cloudflare-dns.com/dns-query?name=gignsky.com&type=A"

# Query MX records
curl -H "accept: application/dns-json" \
  "https://cloudflare-dns.com/dns-query?name=gignsky.com&type=MX"

# Query TXT records (useful for domain verification)
curl -H "accept: application/dns-json" \
  "https://cloudflare-dns.com/dns-query?name=gignsky.com&type=TXT"
```

#### IPv4 vs IPv6 Testing
```bash
# Force IPv4
curl -4 https://gignsky.com

# Force IPv6
curl -6 https://gignsky.com

# Test both and compare
echo "IPv4 test:" && curl -4 -w "Total time: %{time_total}s\n" -o /dev/null -s https://gignsky.com
echo "IPv6 test:" && curl -6 -w "Total time: %{time_total}s\n" -o /dev/null -s https://gignsky.com
```

### DNS Cache Issues

#### Bypass DNS Caching
```bash
# Force fresh DNS lookup (disable DNS cache)
curl --dns-servers 1.1.1.1 --resolve gignsky.com:443:0.0.0.0 https://gignsky.com

# Test with random subdomain to bypass cache
curl https://test-$(date +%s).gignsky.com
```

#### DNS Propagation Testing
```bash
# Test DNS propagation across multiple servers
dns_servers=("1.1.1.1" "8.8.8.8" "9.9.9.9" "208.67.222.222")
domain="gignsky.com"

for server in "${dns_servers[@]}"; do
  echo "Testing with DNS server: $server"
  curl --dns-servers $server -I https://$domain 2>&1 | head -1
  echo "---"
done
```

### DDNS and Dynamic DNS Testing

Perfect for your DDNS updater project and domain management:

```bash
# Check current public IP
curl -s https://api.ipify.org
curl -s https://ipinfo.io/ip

# Test DDNS record update (example for Cloudflare)
# Get current DNS record
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"

# Update DNS record
current_ip=$(curl -s https://api.ipify.org)
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"content\":\"$current_ip\"}"
```

---

## HTTP/HTTPS Operations

### Request Methods

#### GET Requests
```bash
# Basic GET
curl https://api.github.com/repos/NixOS/nixpkgs

# GET with headers
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/NixOS/nixpkgs
```

#### POST Requests
```bash
# POST with data
curl -X POST -d "key=value&key2=value2" https://httpbin.org/post

# POST JSON data
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":"data"}' \
  https://httpbin.org/post

# POST from file
curl -X POST -d @data.json \
  -H "Content-Type: application/json" \
  https://httpbin.org/post
```

#### PUT/PATCH/DELETE
```bash
# PUT request
curl -X PUT -d '{"updated":"value"}' \
  -H "Content-Type: application/json" \
  https://httpbin.org/put

# PATCH request
curl -X PATCH -d '{"field":"new_value"}' \
  -H "Content-Type: application/json" \
  https://httpbin.org/patch

# DELETE request
curl -X DELETE https://httpbin.org/delete
```

### Headers and Cookies

#### Custom Headers
```bash
# Single header
curl -H "User-Agent: MyApp/1.0" https://httpbin.org/user-agent

# Multiple headers
curl -H "Accept: application/json" \
     -H "Authorization: Bearer token123" \
     -H "X-Custom-Header: value" \
     https://httpbin.org/headers

# Remove default headers
curl -H "User-Agent:" https://httpbin.org/user-agent
```

#### Cookie Management
```bash
# Send cookies
curl -b "sessionid=abc123" https://httpbin.org/cookies

# Save cookies to file
curl -c cookies.txt https://httpbin.org/cookies/set/session/value

# Load cookies from file
curl -b cookies.txt https://httpbin.org/cookies

# Cookie jar (save and load)
curl -c cookies.txt -b cookies.txt https://httpbin.org/cookies
```

---

## Authentication Methods

### Basic Authentication
```bash
# Basic auth with username:password
curl -u username:password https://httpbin.org/basic-auth/username/password

# Basic auth with prompt for password
curl -u username https://httpbin.org/basic-auth/username/password

# Basic auth header manually
curl -H "Authorization: Basic $(echo -n username:password | base64)" \
  https://httpbin.org/basic-auth/username/password
```

### Bearer Token Authentication
```bash
# Bearer token
curl -H "Authorization: Bearer your_token_here" \
  https://api.github.com/user

# Environment variable token
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user
```

### API Key Authentication
```bash
# API key in header
curl -H "X-API-Key: your_api_key" https://api.example.com/data

# API key in query parameter
curl "https://api.example.com/data?api_key=your_api_key"
```

---

## Data Transfer and File Operations

### File Uploads

#### Form Data Upload
```bash
# Upload file as form data
curl -F "file=@/path/to/file.txt" https://httpbin.org/post

# Upload with additional form fields
curl -F "file=@document.pdf" \
     -F "description=Important document" \
     https://httpbin.org/post

# Upload multiple files
curl -F "file1=@file1.txt" \
     -F "file2=@file2.txt" \
     https://httpbin.org/post
```

#### Binary Upload
```bash
# Upload binary data
curl --data-binary @file.zip \
  -H "Content-Type: application/zip" \
  https://httpbin.org/post

# Upload from stdin
echo "data" | curl --data-binary @- https://httpbin.org/post
```

### File Downloads

#### Download Files
```bash
# Download and save with original name
curl -O https://releases.nixos.org/nix/nix-2.18.1/install

# Download and save with custom name
curl -o nix-installer.sh https://releases.nixos.org/nix/nix-2.18.1/install

# Download with progress bar
curl --progress-bar -O https://example.com/largefile.zip

# Resume interrupted download
curl -C - -O https://example.com/largefile.zip
```

#### Conditional Downloads
```bash
# Download only if newer than local file
curl -z local_file.txt -O https://example.com/remote_file.txt

# Download only if modified since date
curl -z "2023-01-01" -O https://example.com/file.txt
```

---

## Advanced Networking

### Proxy Configuration

#### HTTP/HTTPS Proxies
```bash
# Use HTTP proxy
curl --proxy http://proxy.example.com:8080 https://httpbin.org/ip

# Use proxy with authentication
curl --proxy-user username:password \
  --proxy http://proxy.example.com:8080 \
  https://httpbin.org/ip

# Use SOCKS proxy
curl --socks5 127.0.0.1:1080 https://httpbin.org/ip
```

#### Proxy Bypass
```bash
# Bypass proxy for specific domains
curl --noproxy "localhost,127.0.0.1,*.local" \
  --proxy http://proxy.example.com:8080 \
  https://localhost:8080/
```

### Network Interface Selection
```bash
# Use specific network interface
curl --interface eth0 https://httpbin.org/ip

# Bind to specific local IP
curl --interface 192.168.1.100 https://httpbin.org/ip
```

### Connection Control

#### Timeouts
```bash
# Connection timeout
curl --connect-timeout 10 https://example.com

# Maximum operation time
curl --max-time 30 https://example.com

# DNS timeout
curl --dns-servers 8.8.8.8 --connect-timeout 5 https://example.com
```

#### Retry Logic
```bash
# Retry on failure
curl --retry 3 --retry-delay 2 https://unreliable-service.com

# Retry only on specific errors
curl --retry 3 --retry-connrefused https://example.com
```

---

## API Testing and Development

### Testing REST APIs

Perfect for your container management and infrastructure automation:

#### Container Health Checks
```bash
# Check container health endpoint
curl -f http://localhost:8080/health

# Check with timeout for automated scripts
curl --max-time 5 -f http://spacedock.local:8080/health || echo "Service down"

# Monitor multiple services
services=("nginx:80" "redis:6379" "postgres:5432")
for service in "${services[@]}"; do
  IFS=':' read -r host port <<< "$service"
  if curl --max-time 2 -s http://$host:$port/health > /dev/null; then
    echo "✓ $service is healthy"
  else
    echo "✗ $service is unhealthy"
  fi
done
```

#### API Response Validation
```bash
# Validate JSON response structure
curl -s https://api.github.com/repos/NixOS/nixpkgs | jq '.name'

# Test API response time
curl -w "Response time: %{time_total}s\n" -o /dev/null -s https://api.example.com

# Validate HTTP status codes
status=$(curl -w "%{http_code}" -s -o /dev/null https://api.example.com)
if [ "$status" -eq 200 ]; then
  echo "API is responding correctly"
else
  echo "API returned status: $status"
fi
```

### Cloudflare API Integration

Specifically for your domain management and DDNS projects:

```bash
# List all zones
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json"

# Get specific zone details
curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN"

# List DNS records for a zone
curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN"

# Create DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "subdomain",
    "content": "192.168.1.100",
    "ttl": 3600
  }'

# Update DNS record
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "content": "192.168.1.101"
  }'

# Purge cache for domain
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

---

## Debugging and Monitoring

### Verbose Output and Tracing

#### Debug Connection Issues
```bash
# Full verbose output
curl -v https://gignsky.com

# Trace ASCII dump of data
curl --trace-ascii trace.txt https://example.com

# Trace binary dump
curl --trace trace.bin https://example.com

# Time operation phases
curl -w "@curl-format.txt" -o /dev/null -s https://example.com
```

Create `curl-format.txt`:
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
         remote_ip:  %{remote_ip}\n
         remote_port:  %{remote_port}\n
         local_ip:  %{local_ip}\n
         local_port:  %{local_port}\n
```

### Network Path Analysis

#### Route and Connection Testing
```bash
# Test direct connection vs CDN
curl -w "Remote IP: %{remote_ip}\n" -o /dev/null -s https://gignsky.com

# Test different endpoints
endpoints=("gignsky.com" "git.gignsky.com" "www.gignsky.com")
for endpoint in "${endpoints[@]}"; do
  echo "Testing $endpoint:"
  curl -w "  IP: %{remote_ip}, Time: %{time_total}s\n" -o /dev/null -s https://$endpoint
done

# Test geographic routing (if using CDN)
curl -H "CF-IPCountry: US" -w "US: %{remote_ip}\n" -o /dev/null -s https://gignsky.com
curl -H "CF-IPCountry: EU" -w "EU: %{remote_ip}\n" -o /dev/null -s https://gignsky.com
```

### Health Monitoring Scripts

#### Service Monitor
```bash
#!/bin/bash
# Service health monitor for your infrastructure

services=(
  "https://gignsky.com"
  "https://git.gignsky.com"
  "http://spacedock.local:8080"
  "http://memory-alpha.local:8080"
)

for service in "${services[@]}"; do
  if curl --max-time 10 -f -s "$service" > /dev/null; then
    echo "$(date): ✓ $service is healthy"
  else
    echo "$(date): ✗ $service is down" >&2
    # Add notification logic here
  fi
done
```

#### Performance Monitor
```bash
#!/bin/bash
# Monitor response times

url="https://gignsky.com"
threshold=2.0

response_time=$(curl -w "%{time_total}" -o /dev/null -s "$url")

if (( $(echo "$response_time > $threshold" | bc -l) )); then
  echo "$(date): WARNING: $url response time: ${response_time}s"
else
  echo "$(date): OK: $url response time: ${response_time}s"
fi
```

---

## Security and Certificates

### SSL/TLS Certificate Testing

#### Certificate Information
```bash
# Show certificate details
curl -vI https://gignsky.com 2>&1 | grep -E "(subject|issuer|expire)"

# Get full certificate chain
openssl s_client -connect gignsky.com:443 -servername gignsky.com < /dev/null

# Test specific TLS versions
curl --tlsv1.2 https://gignsky.com
curl --tlsv1.3 https://gignsky.com

# Test certificate without validation (dangerous!)
curl -k https://self-signed.example.com
```

#### Certificate Validation
```bash
# Check certificate expiry
echo | openssl s_client -servername gignsky.com -connect gignsky.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# Verify certificate chain
curl --cert-status https://gignsky.com

# Test OCSP stapling
echo | openssl s_client -connect gignsky.com:443 -status 2>/dev/null | \
  grep -A 17 "OCSP response"
```

### Client Certificates

#### Using Client Certificates
```bash
# Use client certificate
curl --cert client.crt --key client.key https://api.example.com

# Use client certificate with passphrase
curl --cert client.p12:password https://api.example.com

# Use CA bundle
curl --cacert ca-bundle.crt https://internal-api.company.com
```

---

## Performance Testing

### Load Testing

#### Basic Load Testing
```bash
# Simple concurrent requests
for i in {1..10}; do
  curl -w "%{time_total}\n" -o /dev/null -s https://gignsky.com &
done
wait

# Timed requests
for i in {1..100}; do
  curl -w "%{time_total},%{http_code}\n" -o /dev/null -s https://gignsky.com
  sleep 0.1
done
```

#### Bandwidth Testing
```bash
# Download speed test
curl -w "Downloaded %{size_download} bytes in %{time_total} seconds\nAverage speed: %{speed_download} bytes/sec\n" \
  -o /dev/null -s https://speed.cloudflare.com/__down?bytes=100000000

# Upload speed test
dd if=/dev/zero bs=1M count=10 2>/dev/null | \
  curl -w "Uploaded in %{time_total} seconds\nAverage speed: %{speed_upload} bytes/sec\n" \
  --data-binary @- -o /dev/null -s https://httpbin.org/post
```

### Caching Analysis

#### Cache Headers Testing
```bash
# Check cache headers
curl -I https://gignsky.com

# Test cache validation
curl -H "If-None-Match: \"etag-value\"" -I https://gignsky.com
curl -H "If-Modified-Since: Wed, 21 Oct 2023 07:28:00 GMT" -I https://gignsky.com

# Test cache busting
curl "https://gignsky.com?cache_bust=$(date +%s)"
```

---

## Automation and Scripting

### Nushell Integration

Perfect for your nushell-based workflow:

```nushell
# Get API data as structured data
def get-github-repo [repo: string] {
  curl -s $"https://api.github.com/repos/($repo)" | from json
}

# Check service health
def check-services [] {
  let services = [
    "https://gignsky.com"
    "https://git.gignsky.com"
  ]
  
  $services | each { |service|
    let response = (curl -w "%{http_code},%{time_total}" -o /dev/null -s $service)
    let parts = ($response | split column "," code time)
    {
      service: $service
      status: $parts.code
      response_time: ($parts.time | into float)
      healthy: ($parts.code == "200")
    }
  }
}

# Update DNS record via Cloudflare API
def update-dns-record [zone_id: string, record_id: string, ip: string] {
  let token = $env.CLOUDFLARE_TOKEN
  curl -X PATCH $"https://api.cloudflare.com/client/v4/zones/($zone_id)/dns_records/($record_id)" \
    -H $"Authorization: Bearer ($token)" \
    -H "Content-Type: application/json" \
    --data $'{"content":"($ip)"}' | from json
}
```

### Bash Automation Scripts

#### DDNS Updater Script
```bash
#!/bin/bash
# DDNS updater for Cloudflare - perfect for your DDNS project

CLOUDFLARE_TOKEN="your_token_here"
ZONE_ID="your_zone_id"
RECORD_NAME="home.gignsky.com"

# Get current public IP
current_ip=$(curl -s https://api.ipify.org)

# Get current DNS record
record_info=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json")

# Extract record ID and current IP from DNS
record_id=$(echo "$record_info" | jq -r '.result[0].id')
dns_ip=$(echo "$record_info" | jq -r '.result[0].content')

# Update if IPs don't match
if [ "$current_ip" != "$dns_ip" ]; then
  echo "Updating DNS record from $dns_ip to $current_ip"
  
  update_result=$(curl -s -X PATCH \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
    -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"content\":\"$current_ip\"}")
  
  if echo "$update_result" | jq -r '.success' | grep -q true; then
    echo "DNS update successful"
  else
    echo "DNS update failed"
    echo "$update_result" | jq '.errors'
  fi
else
  echo "DNS record is up to date"
fi
```

#### Container Health Monitor
```bash
#!/bin/bash
# Monitor container health across your infrastructure

declare -A services=(
  ["nginx"]="http://spacedock.local:80/health"
  ["redis"]="http://spacedock.local:6379/ping"
  ["postgres"]="http://spacedock.local:5432/health"
  ["tdarr"]="http://spacedock.local:8265"
)

for service in "${!services[@]}"; do
  url="${services[$service]}"
  
  if curl --max-time 5 -f -s "$url" > /dev/null 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [OK] $service is healthy"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $service is unhealthy" >&2
    
    # Optional: Send notification
    # curl -X POST "$WEBHOOK_URL" -d "{\"text\":\"$service is down\"}"
  fi
done
```

---

## Common Use Cases for Your Projects

### NixOS Configuration Testing

#### Test Nix Binary Cache
```bash
# Test if Nix cache is accessible
curl -I https://cache.nixos.org/

# Check specific NAR availability
curl -I https://cache.nixos.org/nar/specific-hash.nar.xz

# Test custom binary cache (if you set one up)
curl -I https://your-cache.example.com/nix-cache-info
```

#### Flake Registry Testing
```bash
# Test GitHub connectivity for flakes
curl -I https://api.github.com/repos/NixOS/nixpkgs

# Test specific flake endpoint
curl -s https://api.github.com/repos/NixOS/nixpkgs/contents/flake.nix
```

### Container Infrastructure

#### Docker Registry Operations
```bash
# Check if registry is accessible
curl -I https://registry.hub.docker.com/v2/

# List tags for an image
curl -s https://registry.hub.docker.com/v2/repositories/nginx/tags/

# Check local registry (if running one)
curl http://spacedock.local:5000/v2/_catalog
```

#### Kubernetes/Container Health
```bash
# Check container orchestrator API
curl -k https://kubernetes.local:6443/version

# Monitor container metrics
curl http://spacedock.local:9090/metrics

# Check container logs endpoint
curl "http://spacedock.local:8080/api/v1/logs?container=nginx"
```

### Git Infrastructure

#### Git Server Health
```bash
# Test git.gignsky.com availability
curl -I https://git.gignsky.com

# Test Git LFS endpoint
curl -I https://git.gignsky.com/repo.git/info/lfs

# Test SSH Git access via HTTP
curl -I https://git.gignsky.com/repo.git/info/refs?service=git-upload-pack
```

### Network Infrastructure Monitoring

#### Router/Switch Management
```bash
# Test layer 3 switch web interface
curl --connect-timeout 5 -I http://192.168.1.1

# Monitor DHCP server
curl "http://192.168.1.1/api/dhcp/leases"

# Check OpenWRT status (for future router project)
curl -u admin:password http://192.168.1.1/cgi-bin/luci/admin/status/overview
```

---

## Troubleshooting Common Issues

### DNS Resolution Problems

#### Symptoms and Solutions
```bash
# Problem: "Could not resolve host"
# Solution: Test with different DNS servers
curl --dns-servers 1.1.1.1,8.8.8.8 https://problematic-domain.com

# Problem: "SSL certificate problem"
# Solution: Check certificate chain
curl -vI https://problematic-domain.com 2>&1 | grep -i certificate

# Problem: Slow DNS resolution
# Solution: Compare DNS servers
for dns in 1.1.1.1 8.8.8.8 9.9.9.9; do
  echo "Testing DNS: $dns"
  time curl --dns-servers $dns -w "%{time_namelookup}\n" -o /dev/null -s https://example.com
done
```

### Connection Issues

#### Network Connectivity
```bash
# Test basic connectivity
curl --connect-timeout 10 https://example.com

# Test with different protocols
curl http://example.com     # HTTP
curl https://example.com    # HTTPS
curl ftp://example.com      # FTP

# Test through different routes
curl --interface eth0 https://example.com
curl --interface wlan0 https://example.com
```

#### Proxy Problems
```bash
# Bypass proxy for testing
curl --noproxy "*" https://example.com

# Test proxy connectivity
curl --proxy http://proxy:8080 http://httpbin.org/ip

# Test proxy authentication
curl --proxy-user user:pass --proxy http://proxy:8080 https://example.com
```

### SSL/TLS Issues

#### Certificate Problems
```bash
# Ignore certificate errors (temporary)
curl -k https://self-signed.example.com

# Use specific CA bundle
curl --cacert /path/to/ca-bundle.crt https://internal.company.com

# Test different TLS versions
curl --tls-max 1.2 https://example.com
curl --tls-max 1.3 https://example.com
```

---

## Best Practices

### Security

1. **Never log sensitive data**: Use `-s` with authentication
2. **Validate certificates**: Avoid `-k` in production
3. **Use environment variables**: Store tokens/passwords in env vars
4. **Rotate credentials**: Regularly update API keys and tokens

### Performance

1. **Use connection reuse**: `--keepalive-time` for multiple requests
2. **Set appropriate timeouts**: Prevent hanging scripts
3. **Compress transfers**: Use `--compressed` for large responses
4. **Limit redirects**: Use `--max-redirs` to prevent infinite loops

### Automation

1. **Always check exit codes**: `curl -f` or check `$?`
2. **Log appropriately**: Use structured logging for monitoring
3. **Handle failures gracefully**: Implement retry logic
4. **Monitor performance**: Track response times and success rates

### Configuration Management

Create `~/.curlrc` for default options:
```bash
# Default options
--location
--show-error
--remote-time
--netrc-optional
```

---

## Quick Reference

### Essential Commands for Daily Use

```bash
# Quick health check
curl -f -s -o /dev/null https://example.com && echo "OK" || echo "FAIL"

# Get response time
curl -w "%{time_total}\n" -o /dev/null -s https://example.com

# Check HTTP status
curl -w "%{http_code}\n" -o /dev/null -s https://example.com

# Download with progress
curl --progress-bar -o file.zip https://example.com/file.zip

# JSON API call
curl -H "Content-Type: application/json" -d '{"key":"value"}' https://api.example.com

# Test with different user agent
curl -H "User-Agent: MyBot/1.0" https://example.com

# Follow redirects with limit
curl -L --max-redirs 5 https://example.com

# Save response headers
curl -D headers.txt https://example.com
```

### Format Strings for `-w` Option

```bash
%{content_type}      # Content-Type of response
%{filename_effective} # Effective filename for download
%{ftp_entry_path}    # Initial path for FTP
%{http_code}         # HTTP status code
%{http_connect}      # HTTP CONNECT response code
%{local_ip}          # Local IP address
%{local_port}        # Local port number
%{num_connects}      # Number of connections made
%{num_redirects}     # Number of redirects followed
%{redirect_url}      # Redirect URL if redirect would happen
%{remote_ip}         # Remote IP address
%{remote_port}       # Remote port number
%{size_download}     # Total bytes downloaded
%{size_header}       # Total bytes of headers
%{size_request}      # Total bytes sent
%{size_upload}       # Total bytes uploaded
%{speed_download}    # Average download speed
%{speed_upload}      # Average upload speed
%{ssl_verify_result} # SSL verification result
%{time_appconnect}   # Time for SSL/TLS handshake
%{time_connect}      # Time for connection establishment
%{time_namelookup}   # Time for name resolution
%{time_pretransfer}  # Time before transfer start
%{time_redirect}     # Time for redirects
%{time_starttransfer} # Time to first byte
%{time_total}        # Total time for operation
%{url_effective}     # Effective URL fetched
```

### Exit Codes

- `0`: Success
- `1`: Unsupported protocol
- `2`: Failed to initialize
- `3`: URL malformed
- `4`: URL feature not supported
- `5`: Couldn't resolve proxy
- `6`: Couldn't resolve host
- `7`: Failed to connect
- `22`: HTTP error (when using `-f`)
- `28`: Timeout reached
- `35`: SSL connect error

---

This manual should serve as your comprehensive reference for using curl effectively in your NixOS environment, DNS troubleshooting, infrastructure monitoring, and automation projects. The examples are tailored to your specific use cases including Cloudflare API management, container health monitoring, and network infrastructure debugging.