#!/bin/bash
login=""
pass=""
host=""
remote_dir="" 
local_dir="" # Use an interim folder, not the final destination for plex media
plex_url=""
plex_token=""
trap "rm -f /tmp/gettorrent.lock" SIGINT SIGTERM
if [ -e /tmp/gettorrent.lock ]
then
echo "GetTorrents is running already."
exit 0
else
touch /tmp/gettorrent.lock
function scanlibrary {
   curl "http://${plex_url}:32400/library/sections/${1}/refresh?X-Plex-Token=${plex_token}"
}
lftp -p 22 -u $login,$pass sftp://$host << EOF
mirror --exclude .sync --exclude @eaDir/ --exclude seeding -v -p --Move -c -P5 --use-pget-n=60 --log=sendtorrents.log $remote_dir $local_dir
quit
EOF
(filebot -script 'fn:amc' /volume1/plex-transfer/hdmov --output /volume1/plex/hdmov --action move -non-strict --order Airdate --conflict auto --lang en --def 'ut_label=Movie' 'music=y' 'clean=y' 'unsorted=y' 'skipExtract=y' 'movieFormat={"$plex.tail"}{" [$vf, $vc-$bitdepth, $ac]"}' 'excludeList=.excludes' && scanlibrary 1) || true
(filebot -script 'fn:amc' /volume1/plex-transfer/sdmov --output /volume1/plex/sdmov --action move -non-strict --order Airdate --conflict auto --lang en --def 'ut_label=Movie' 'music=y' 'clean=y' 'unsorted=y' 'skipExtract=y' 'movieFormat={"$plex.tail"}{" [$vf, $vc-$bitdepth, $ac]"}' 'excludeList=.excludes' && scanlibrary 1) || true
(filebot -script 'fn:amc' /volume1/plex-transfer/sdtv --output /volume1/plex/sdtv --action move -non-strict --order Airdate --conflict auto --lang en --filter '!(n =~ /Vekterne|Nachtwacht|Comic/)' --def 'ut_label=TV' 'music=y' 'unsorted=y' 'clean=y' 'skipExtract=y' 'seriesFormat={"$plex.tail"}{" [$vf, $vc-$bitdepth, $ac]"}' 'excludeList=.excludes' && scanlibrary 2) || true
(filebot -script 'fn:amc' /volume1/plex-transfer/hdtv --output /volume1/plex/hdtv --action move -non-strict --order Airdate --conflict auto --lang en --filter '!(n =~ /Vekterne|Nachtwacht|Comic/)' --def 'ut_label=TV' 'music=y' 'unsorted=y' 'clean=y' 'skipExtract=y' 'seriesFormat={"$plex.tail"}{" [$vf, $vc-$bitdepth, $ac]"}' 'excludeList=.excludes' && scanlibrary 2) || true
# Remove oldest logfile
find /volume1/plex/scripts/synoscheduler/6/ -type d -printf '%T+ %p\n' | sort  | head -n 1 | awk '{print $NF}' | xargs rm -rf
rm -f /tmp/gettorrent.lock
trap - SIGINT SIGTERM
exit 0
fi
