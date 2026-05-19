#!/bin/bash
# EC2 Canvas bootstrap: rebuild JS packages + webpack bundles, enable +Course, seed test course.
# Run on EC2: bash agents/scripts/ec2-bootstrap-fix.sh
# Safe to re-run; skips course creation if "What-If Test Course" already exists.
set -euo pipefail

cd ~/canvas-lms-master

log() { echo "[$(date +%H:%M:%S)] $*"; }

log "=== Phase 0: compose + containers ==="
test -f .env || echo "COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:docker-compose.ec2.yml" > .env
docker compose ps --format 'table {{.Name}}\t{{.Status}}' || true

log "=== Phase 1: stop webpack (serving stale bundles) ==="
docker compose stop webpack || true

log "=== Phase 2: yarn + build workspace packages ==="
find packages -path "*/scripts/*" -type f -exec chmod +x {} \; 2>/dev/null || true
docker compose run --rm web yarn install
docker compose run --rm web yarn workspace @instructure/canvas-media build
docker compose run --rm web yarn workspace @instructure/canvas-rce build

log "=== Phase 2b: verify built files inside container ==="
docker compose run --rm --no-deps web test -f packages/canvas-rce/es/enhance-user-content/index.js
docker compose run --rm --no-deps web test -f packages/canvas-media/es/index.js
log "Package es/ artifacts OK"

log "=== Phase 3: wipe stale webpack-dev output ==="
docker compose run --rm --no-deps web rm -rf public/dist/webpack-dev

log "=== Phase 4: full webpack rebuild (15-25 min — do not interrupt) ==="
docker compose run --rm web bundle exec rake js:webpack_development

log "=== Phase 5: feature flag + test course ==="
docker compose exec -T web bundle exec rails runner agents/scripts/setup_course.rb

log "=== Phase 6: restart services ==="
docker compose up -d web webpack jobs postgres redis
sleep 25

log "=== Phase 7: verify ==="
docker compose ps --format 'table {{.Name}}\t{{.Status}}' | grep -E 'webpack|web' || true
docker compose run --rm --no-deps web test -f public/dist/webpack-dev/webpack-manifest.json
log "webpack-manifest.json OK"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || true)
IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_EC2_IP")

echo ""
echo "============================================"
echo "DONE. Hard refresh (Ctrl+Shift+R):"
echo "  http://${IP}/"
echo "+ Course should open a modal."
echo "What-If Test Course should appear in All Courses."
echo "============================================"
