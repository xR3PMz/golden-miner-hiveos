#!/usr/bin/env bash

####################################################################################
###
### Nockminer - Golden
### Hive integration: UnRe4L
###
####################################################################################

cd `dirname $0`

ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
ITALIC='\033[3m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

echo ""
echo ""
echo ""
echo -e "${BLUE}"
echo "  ██╗  ██╗ █████╗ ███████╗██╗  ██╗ █████╗ ██╗    "
echo "  ██║  ██║██╔══██╗██╔════╝██║  ██║██╔══██╗██║    "
echo "  ███████║███████║███████╗███████║███████║██║    "
echo "  ██╔══██║██╔══██║╚════██║██╔══██║██╔══██║██║    "
echo -e "  ██║  ██║██║  ██║███████║██║  ██║██║  ██║██║ "
echo -e "  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ "
echo ""
echo -e "${CYAN}          GOLDEN MINER - HiveOS TEST                  ${RESET}"
echo -e "${ITALIC}${BOLD}             WWW.ADVANCED-HASH.AI              ${RESET}"
echo ""
echo -e "${BOLD}  Github du boss: https://github.com/GoldenMinerNetwork/ 🛠️   ${RESET}"
echo ""

[ -t 1 ] && . colors

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. $SCRIPT_DIR/h-manifest.conf
echo ""

[[ -z $CUSTOM_LOG_BASENAME ]] && echo -e "${RED}No CUSTOM_LOG_BASENAME is set${NOCOLOR}" && exit 1
[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1

LOG_FILE="$SCRIPT_DIR/$CUSTOM_MINERBIN.log"
TMP_FILE="$SCRIPT_DIR/$CUSTOM_MINERBIN.tmp"
argz="$(< $CUSTOM_USER_CONFIG_FILENAME)"

  echo ""
  echo -e "${RED}${BOLD} Settings:${RESET} $argz"
  echo ""

  $SCRIPT_DIR/screen-kill nock

./nock $argz 2>&1 | while IFS= read -r line; do
    echo "$line"                     # sortie pour motd watch
    echo "$line" >> "$TMP_FILE"      # ajout temporaire
    tail -n 15 "$TMP_FILE" > "$LOG_FILE"   # tronquer à 15 lignes
done

tail -f /dev/null
