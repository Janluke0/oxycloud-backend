terraform output |\
sed "/HOSTING_BUCKET/d" |\
sed "/WEBSITE_URL/d" |\
sed "s/ = /=/g; s/\"//g; s/^/REACT_APP_/g "