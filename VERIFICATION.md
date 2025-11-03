# FAIR + AspireCloud Verification Guide

This guide helps you verify that WordPress is correctly using the local AspireCloud instance through FAIR.

## Quick Verification Checklist

### ✅ 1. Services Running

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep cloudfest
```

You should see:
- `cloudfest-aspirecloud` (healthy or running)
- `cloudfest-aspirecloud-db` (healthy)
- `cloudfest-redis` (healthy)
- `cloudfest-traefik`
- `cloudfest-mailhog`
- `cloudfest-adminer`

And WordPress containers:
- `...-wordpress-1`
- `...-tests-wordpress-1`

### ✅ 2. WordPress Connected to Network

```bash
docker network inspect cloudfest-network | grep wordpress
```

Should show both WordPress containers connected to `cloudfest-network`.

### ✅ 3. AspireCloud Accessible from WordPress

```bash
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) curl -s "http://aspirecloud:80/plugins/info/1.2/" | head -5
```

Should return JSON with plugin information.

### ✅ 4. FAIR Plugin Active

```bash
npm run wp:cli -- plugin list | grep main
```

Should show `main` plugin as `active`.

### ✅ 5. MU-Plugin Loaded

```bash
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) cat /var/www/html/wp-content/mu-plugins/fair-config.php | head -5
```

Should display the FAIR configuration file.

### ✅ 6. FAIR Configuration Correct

```bash
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) grep -r "FAIR_DEFAULT_REPO_DOMAIN" /var/www/html/wp-content/mu-plugins/
```

Should show: `define('FAIR_DEFAULT_REPO_DOMAIN', 'aspirecloud:80');`

## In-Depth Verification

### Test Plugin API Requests

```bash
# Check AspireCloud logs before making request
docker logs cloudfest-aspirecloud --tail 5

# Trigger a plugin search from WordPress
npm run wp:cli -- plugin search --per-page=1 wordpress-seo

# Check AspireCloud logs again
docker logs cloudfest-aspirecloud --tail 10
```

You should see new log entries showing requests from WordPress with User-Agent like `WordPress/6.x.x`.

### Test in WordPress Admin

1. **Go to WordPress Admin**
   - URL: http://localhost:8888/wp-admin
   - Username: `admin`
   - Password: `password`

2. **Check Dashboard Notice**
   - Should see: "CloudFest Hackathon: FAIR plugin is configured to use local AspireCloud at http://aspirecloud:80"

3. **Test Plugin Installation**
   - Go to: Plugins → Add New
   - Search for any plugin (e.g., "contact form")
   - Click "Install Now" on any plugin
   - **Expected**: Plugin should download and install successfully
   - **If it fails**: Check the troubleshooting section below

4. **Check Plugin Thumbnails**
   - On the "Add Plugins" page, plugin thumbnails should be visible
   - **If broken**: The URL rewriting in mu-plugin may need adjustment

### Monitor Live Requests

Open two terminals:

**Terminal 1 - Watch AspireCloud logs:**
```bash
docker logs -f cloudfest-aspirecloud
```

**Terminal 2 - Browse WordPress admin:**
```bash
# Open browser to http://localhost:8888/wp-admin
# Navigate to Plugins → Add New
# Search for plugins
```

You should see requests appear in Terminal 1 showing WordPress querying AspireCloud.

## Expected Behavior

### ✅ Plugin Search
- Queries go to `http://aspirecloud:80/plugins/info/1.2/`
- Results return from local AspireCloud database
- FAIR adds `&_fair=1.0.0` parameter to requests

### ✅ Plugin Installation
- Download URLs are rewritten from `https://api.aspiredev.local/download/...` to `http://aspirecloud:80/download/...`
- WordPress downloads plugin ZIP from local AspireCloud
- Installation proceeds normally

### ✅ Plugin Icons/Thumbnails
- Icon URLs are rewritten to use `http://aspirecloud:80`
- Images load in WordPress admin

## Troubleshooting

### Issue: "Download failed. A valid URL was not provided"

**Cause**: AspireCloud is returning URLs that WordPress can't access.

**Solution**:
```bash
# 1. Check mu-plugin is loaded
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) \
  cat /var/www/html/wp-content/mu-plugins/fair-config.php | grep plugins_api_result

# 2. If empty, mu-plugin isn't loaded - restart WordPress
npm run wp:stop && npm run wp:start

# 3. Verify URL rewriting is working
npm run wp:cli -- eval "
  \$result = plugins_api('plugin_information', (object)['slug' => 'hello-dolly']);
  echo \$result->download_link . PHP_EOL;
"

# Should output: http://aspirecloud:80/download/plugin/hello-dolly.x.x.x.zip
```

### Issue: Plugin thumbnails broken

**Cause**: Icon URLs not being rewritten.

**Solution**: Same as above - ensure mu-plugin is loaded and restart WordPress.

### Issue: Requests still going to wordpress.org or production AspireCloud

**Cause**: FAIR_DEFAULT_REPO_DOMAIN not set correctly.

**Solution**:
```bash
# Check the constant
npm run wp:cli -- eval "
  if (defined('FAIR_DEFAULT_REPO_DOMAIN')) {
    echo 'FAIR_DEFAULT_REPO_DOMAIN: ' . FAIR_DEFAULT_REPO_DOMAIN;
  } else {
    echo 'NOT DEFINED';
  }
"

# Should output: aspirecloud:80

# If not, check mu-plugin and restart
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) \
  cat /var/www/html/wp-content/mu-plugins/fair-config.php

npm run wp:stop && npm run wp:start
```

### Issue: WordPress can't reach AspireCloud

**Cause**: WordPress container not on `cloudfest-network`.

**Solution**:
```bash
# Reconnect to network
WORDPRESS_ID=$(docker ps -qf 'name=.*-wordpress-1' | head -1)
docker network connect cloudfest-network "$WORDPRESS_ID"

# Test connectivity
docker exec "$WORDPRESS_ID" curl -s http://aspirecloud:80/
```

### Issue: AspireCloud not returning data

**Cause**: Database not imported or AspireCloud unhealthy.

**Solution**:
```bash
# Check AspireCloud status
docker ps | grep aspirecloud

# Check database
npm run db:import

# Restart AspireCloud
docker-compose restart aspirecloud
```

## Advanced Debugging

### Enable WordPress Debug Logging

```bash
npm run wp:cli -- config set WP_DEBUG_LOG true --raw
npm run wp:cli -- config set WP_DEBUG true --raw
```

View logs:
```bash
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) tail -f /var/www/html/wp-content/debug.log
```

### Trace HTTP Requests

Add this to `wp-content/mu-plugins/fair-config.php`:

```php
add_filter('pre_http_request', function($preempt, $args, $url) {
    error_log('[HTTP Request] ' . $url);
    return $preempt;
}, 1, 3);
```

Then watch the debug log while browsing WordPress admin.

### Inspect plugins_api Results

```bash
npm run wp:cli -- eval "
  \$result = plugins_api('plugin_information', (object)['slug' => 'hello-dolly']);
  print_r([
    'download_link' => \$result->download_link,
    'icons' => \$result->icons,
  ]);
"
```

All URLs should start with `http://aspirecloud:80`.

## Success Indicators

When everything is working correctly:

✅ Plugin searches return results from local AspireCloud
✅ AspireCloud logs show requests from WordPress
✅ Download URLs point to `http://aspirecloud:80`
✅ Plugins can be installed successfully
✅ Plugin thumbnails display correctly
✅ No errors in WordPress debug log
✅ Dashboard shows FAIR configuration notice

## Quick Reset

If things get messed up:

```bash
# Complete environment reset
npm run dev:reset

# Fresh start
npm install
npm run dev:start

# Wait for everything to start, then verify
docker ps
npm run wp:cli -- plugin list
```

## For Hackathon Participants

Once verified, you can:

1. **Develop custom plugins** that query local AspireCloud
2. **Test FAIR DID resolution** with local data
3. **Integrate PatchStack API** for vulnerability checking
4. **Build security screening workflows** using local data

All WordPress plugin/theme update checks will route through FAIR to your local AspireCloud instance, perfect for isolated development and testing!
