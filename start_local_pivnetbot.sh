#!/bin/bash

PIVNETBOT_MONITORED_CHANNEL_IDS=one_channel,another_channel \
PIVNETBOT_TOKEN=123 \
PIVNETBOT_SLACK_URL=https://hooks.slack.com/services/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 \
PIVNETBOT_KEYWORDS=hello,world \
PIVNETBOT_IGNORED_USER_IDS=one_user_id,another_user_id \
ruby pivnetbot.rb

