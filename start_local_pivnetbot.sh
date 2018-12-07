#!/bin/bash

PIVNETBOT_TOKEN=123 \
PIVNETBOT_SLACK_URL=https://hooks.slack.com/services/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 \
PIVNETBOT_KEYWORDS=hello,world,several\ word\ keyword \
PIVNETBOT_GOOGLE_SHEETS_CREDENTIALS='<redacted>'
PIVNETBOT_SPREADSHEET_TITLE='pivnetbot_test' \
ruby pivnetbot.rb

