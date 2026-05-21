do shell script "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; pbpaste | jq . | pbcopy"
display alert "Format JSON" message "JSON formatted on clipboard" giving up after 1
