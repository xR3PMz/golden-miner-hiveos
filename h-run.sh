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

#echo -e "${GREEN}> Starting $CUSTOM_MINERBIN${NOCOLOR}"
#echo -e "${GREEN}> ./$CUSTOM_MINERBIN $(< $CUSTOM_CONFIG_FILENAME)${NOCOLOR}"

#./$CUSTOM_MINERBIN $(< $CUSTOM_CONFIG_FILENAME) $@ 2>&1 | tee $CUSTOM_LOG_BASENAME.log


# parse args
parse_args() {
    local args="$1"
    shift
    local keys=("$@")

    read -ra tokens <<< "$args"
    local filtered=()

    for ((i = 0; i < ${#tokens[@]}; i++)); do
        local token="${tokens[i]}"
        local is_key=0

        for key in "${keys[@]}"; do
            if [[ "$token" == "--$key" ]]; then
                local var_name="${key//-/_}"

                if (( i + 1 < ${#tokens[@]} )); then
                    local value="${tokens[$((i+1))]}"
                    export "${var_name}=$value"
                else
                    export "${var_name}="
                fi

                ((i++))  
                is_key=1
                break
            fi
        done

        if [[ $is_key -eq 0 ]]; then
            filtered+=("${token}")
        fi
    done


    echo "${filtered[*]}"
}

remainingAddition="${REPLY}"

[ -z "$reserved_cores" ] && reserved_cores=4
[ -z "$gpu_count" ] && gpu_count=$(gpu-detect NVIDIA)

total_cores=$(nproc)
gpu_threads=$reserved_cores
required_gpu_cores=$((gpu_count * gpu_threads))
remaining_cpu_threads=$((total_cores - required_gpu_cores))

if (( remaining_cpu_threads < 0 )); then
  echo -e "${YELLOW}[!] Недостаточно потоков CPU для $gpu_threads на каждую из $gpu_count GPU${NOCOLOR}"
  remaining_cpu_threads=0
fi

$LINE

MY_PID=$$

for ((i = 0; i < gpu_count; i++)); do
  screenName="nock"
  apiPort="4444$i"
  log="/var/log/$CUSTOM_MINERBIN$i.log"

  batch="./nock $(< $CUSTOM_USER_CONFIG_FILENAME)"
  argz="$(< $CUSTOM_USER_CONFIG_FILENAME)"
  fullBatch=$(cat <<EOF
(
  ( while kill -0 $MY_PID 2>/dev/null; do sleep 1; done
    echo "GPU $i: parent died, shutting down miner..."
    kill \$\$ ) &

  while true; do $batch 2>&1 | tee -a $log; done
)
EOF
)

  echo ""
  echo -e "${RED}${BOLD} Settings:${RESET} $argz"
  echo ""
  $SCRIPT_DIR/screen-kill $screenName
  #screen -dmS "$screenName" bash -c "$fullBatch"
  ./nock $argz

done

tail -f /dev/null
