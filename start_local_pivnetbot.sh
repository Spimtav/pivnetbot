#!/bin/bash

PIVNETBOT_VERIFICATION_TOKEN=123 \
PIVNETBOT_OAUTH_TOKEN='xyz' \
PIVNETBOT_SLACK_URL='http://www.com' \
PIVNETBOT_KEYWORDS=hello,world,several\ word\ keyword \
PIVNETBOT_GOOGLE_SHEETS_CREDENTIALS='{}' \
PIVNETBOT_SPREADSHEET_TITLE='test' \
bundle exec ruby pivnetbot.rb

