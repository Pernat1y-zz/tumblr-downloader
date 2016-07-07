#!/usr/bin/bash

# Home: https://github.com/Pernat1y/tumblr-downloader
# Tumblr API reference: https://www.tumblr.com/docs/en/api/v2

tumblr_app_key=fuiKNFp9vQFvjLNvx4sUwti4Yb5yGutBN4Xh10LXZhhRKjWlV4

tumblr_blog_url=$1
tumblr_blog_tags=$2
tumblr_post_offset=0
tumble_total_posts=

if [ -z $1 ]; then
	echo "Usage: $0 blog.tumblr.com [tags]"
	exit
fi

which curl jq >>/dev/null
if [ $? -ne "0" ]; then
	echo "I need curl ( https://curl.haxx.se ) and jq ( https://github.com/stedolan/jq ) to work"
	exit
fi

tumble_total_posts=`curl --silent --referer "https://www.tumblr.com/dashboard" --user-agent "Mozilla/5.0" --retry 3 --retry-delay 3 \
"https://api.tumblr.com/v2/blog/$tumblr_blog_url/info?api_key=$tumblr_app_key" |\
jq '.response | .blog | .total_posts'`

echo "There are $tumble_total_posts posts. Getting list of URLs to download..."

mkdir -p "$tumblr_blog_url" 2>/dev/null
cd "$tumblr_blog_url"
if [ $? -ne "0" ]; then
	echo "Unable to create/enter directory. Check free space and permissions on current directory."
	exit
fi

while [ $tumblr_post_offset -lt $tumble_total_posts ]; do
	echo "Processing page $tumblr_post_offset from $tumble_total_posts"
	curl --silent --referer "https://www.tumblr.com/dashboard" --user-agent "Mozilla/5.0" --retry 3 --retry-delay 3 \
	"https://api.tumblr.com/v2/blog/$tumblr_blog_url/posts/photo?api_key=$tumblr_app_key&offset=$tumblr_post_offset&limit=20&tag=$tumblr_blog_tags" |\
	jq '.response | .posts | .[] | .photos | .[] | .original_size | .url' >> $tumblr_blog_url.list
	tumblr_post_offset=`expr $tumblr_post_offset + 20`
	sleep 3
done

echo "Found `cat $tumblr_blog_url.list | wc -l` images. Downloading..."

for tumblr_download_url in `cat $tumblr_blog_url.list | sed 's/\"//g'`; do
	curl --silent --referer "https://www.tumblr.com/dashboard" --user-agent "Mozilla/5.0" \
		--continue-at - --remote-name --remote-name-all --retry 3 --retry-delay 3 $tumblr_download_url
done

echo "Done."

