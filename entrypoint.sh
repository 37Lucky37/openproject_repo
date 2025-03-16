#!/bin/sh
set -e


if [ "$MIGRATE_DB" = "yes" ]; then
  echo "Checking if migrations are needed..."
  if bundle exec rails db:abort_if_pending_migrations RAILS_ENV=production; then
    echo "No pending migrations. Skipping..."
  else
    echo "Running migrations..."
    bundle exec rails db:migrate RAILS_ENV=production
  fi
else
  echo "Skipping database migrations (MIGRATE_DB=$MIGRATE_DB)."
fi


if [ "$PRECOMPILE_ASSETS" = "yes" ]; then
  echo "Compiling assets..."
  RAILS_ENV=production bundle exec rake assets:precompile
else
  echo "Skipping assets precompilation (PRECOMPILE_ASSETS=$PRECOMPILE_ASSETS)."
fi


echo "Starting Puma server..."
exec bundle exec puma -C config/puma.rb -e production


