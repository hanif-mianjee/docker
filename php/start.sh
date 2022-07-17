#!/bin/bash
set -e
role=${CONTAINER_ROLE:-composer}
env=${APP_ENV:-production}

if [ "$env" != "local" ]; then
    echo "Caching configuration..."
    (cd /var/www/html && php artisan config:cache && php artisan route:cache && php artisan view:cache)
fi

if [ "$role" = "composer" ]; then

    echo "Running the composer..."

    cd /var/www/html
    composer install --no-interaction --prefer-dist --optimize-autoloader
    php artisan cache:clear
    php artisan event:clear
    php artisan config:clear
    php artisan view:clear
    php artisan route:clear
    php artisan storage:link

    # Keeping alive
    tail -f /dev/null

elif [ "$role" = "queue" ]; then

    echo "Running the queue..."

    php /var/www/html/artisan queue:work --verbose --tries=3 --timeout=90 > /var/www/html/storage/logs/queue.log

elif [ "$role" = "scheduler" ]; then

    rm -rf /var/www/html/storage/logs/schedule.log

    while [ true ]
    do
      sleep 60
      php /var/www/html/artisan schedule:run --verbose --no-interaction >> /var/www/html/storage/logs/schedule.log
    done

else

    echo "Could not match the container role \"$role\""
    exit 1

fi