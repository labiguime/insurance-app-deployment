#!/bin/sh

echo "Starting to pull assets..."
aws s3 cp s3://haywards-utils/public.tar.gz /usr/share/nginx/html/
echo `tar -C /usr/share/nginx/html/ -xzf /usr/share/nginx/html/public.tar.gz && rm -f /usr/share/nginx/html/public.tar.gz`
echo "Assets pulled!"
