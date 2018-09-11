#!/bin/bash

# execute this script hourly if you want hourly-database backups

BKP_DB_HOST="localhost"
BKP_DB_NAME="dbname"
BKP_DB_USER="root"
BKP_DB_PASS="root"
BKP_FOLDER="/var/www"
BKP_TMP="/home/ubuntu/backups"
BKP_S3_BUCKET="my.s3bucket.aws/backups"
BKP_GLACIER_FOLDER="/home/ubuntu/.aws/config"
AWS_CONFIG_FILE="/home/ubuntu/.aws/config"
AWS_CREDENTIAL_FILE="/home/ubuntu/.aws/credentials"
PATH="/home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"

# date without time, backup is daily
BKP_FOLDER_TODAY=`date +%Y-%m-%d`
BKP_FOLDER_REMOVELOCAL=`date --date="3 days ago" +%Y-%m-%d`
BKP_FOLDER_REMOVE_S3=`date --date="30 days ago" +%Y-%m-%d`

# date with hour, db backup is hourly, but removing from s3 is daily
BKP_DB_NOWTIME=`date +%Y-%m-%d_%H`
BKP_DB_REMOVELOCAL=`date --date="2 days ago" +%Y-%m-%d_%H`
BKP_DB_REMOVE_S3=`date --date="30 days ago" +%Y-%m-%d_%H`

#if backup folder has not been made
if [ ! -f "$BKP_TMP/db_$BKP_DB_NOWTIME.sql.gz" ]; then
    # dump and gzip db
    mysqldump --host="$BKP_DB_HOST" --user="$BKP_DB_USER" --password="$BKP_DB_PASS" $BKP_DB_NAME | gzip -c | cat > $BKP_TMP/db_$BKP_DB_NOWTIME.sql.gz
    # upload to s3
    aws s3 cp $BKP_TMP/db_$BKP_DB_NOWTIME.sql.gz s3://$BKP_S3_BUCKET/
    # delete the local old backup
    if [ -f "$BKP_TMP/db_$BKP_DB_REMOVELOCAL.sql.gz" ]; then
        rm $BKP_TMP/db_$BKP_DB_REMOVELOCAL.sql.gz
    fi
    # delete the old backups on s3
    aws s3 cp s3://$BKP_S3_BUCKET/db_$BKP_DB_REMOVE_S3*
fi

#if backup folder has not been made
if [ ! -f "$BKP_TMP/folder_$BKP_FOLDER_TODAY.tar.gz" ]; then
    # tar.gz folder
    tar -czf $BKP_TMP/folder_$BKP_FOLDER_TODAY.tar.gz www
    # upload to s3
    aws s3 cp $BKP_TMP/folder_$BKP_FOLDER_TODAY.tar.gz s3://$BKP_S3_BUCKET/
    # delete the local old backup
    if [ -f "$BKP_TMP/folder_$BKP_FOLDER_REMOVELOCAL.tar.gz" ]; then
        rm $BKP_TMP/folder_$BKP_FOLDER_REMOVELOCAL.tar.gz
    fi
    # delete the old backup on s3
    aws s3 cp s3://$BKP_S3_BUCKET/folder_$BKP_FOLDER_REMOVE_S3.tar.gz
fi

exit 0
