#!/usr/bin/env bash

####################################################################################
###
### Nockminer - Golden
### Hive integration: UnRe4L
###
####################################################################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. $SCRIPT_DIR/h-manifest.conf

LOG_FILE="$SCRIPT_DIR/$CUSTOM_MINERBIN.log"
algo="nock"

# Nombre de GPU
gpuCount=$(gpu-detect NVIDIA)

# Tableau des hashrates par GPU
declare -a hr_data=()
# for (( i=0; i < gpuCount; i++ )); do
    # Extraire dernière ligne speed X p/s pour GPU i
    lastSpeed=$(grep "Card-0 speed:"  "$LOG_FILE" | tail -n1 | sed -E 's/.*speed:[[:space:]]+[[:space:]]+([0-9.]+) p\/s/\1/')
    [[ $lastSpeed ]] && hr_data[$i]=$lastSpeed || hr_data[$i]=0
# done

# Calcul du total
totalHr=0
for hr in "${hr_data[@]}"; do
    totalHr=$(echo "$totalHr + $hr" | bc)
done

# JSON des hashrates
hr_json=$(printf '%s\n' "${hr_data[@]}" | jq -R . | jq -s .)

# Récupérer infos GPU (fan/temp/busid) depuis GPU_STATS_JSON
busid_json='[]'
fan_json='[]'
temp_json='[]'

gpu_stats=$(< $GPU_STATS_JSON)
readarray -t gpu_stats < <(jq --slurp -r -c '.[] | .brand, .temp, .fan, .busids | join(" ")' $GPU_STATS_JSON 2>/dev/null)
brands=(${gpu_stats[0]})
temps=(${gpu_stats[1]})
fans=(${gpu_stats[2]})
busids=(${gpu_stats[3]})

[[ ${brands[0]} == 'cpu' ]] && internalCpuShift=1 || internalCpuShift=0

for (( i=0; i < gpuCount; i++ )); do
    y=$((i + internalCpuShift))
    fan_json=$(jq ". += [${fans[$y]}]" <<< "$fan_json")
    temp_json=$(jq ". += [${temps[$y]}]" <<< "$temp_json")
    busidHex=$(echo ${busids[$y]} | awk -F ':' '{print $1}' | tr '[:lower:]' '[:upper:]')
    [[ ${busidHex:0:1} == 0 ]] && busidHex=${busidHex:1:2}
    busidDecimal=$(echo "ibase=16; $busidHex" | bc)
    busid_json=$(jq ". += [$busidDecimal]" <<< "$busid_json")
done

# Uptime approximatif (timestamp dernière ligne du log)
uptime=$(grep -oP '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' "$LOG_FILE" | tail -n1)
[[ -z $uptime ]] && uptime=0

# JSON final pour HiveOS
stats=$(jq -n \
    --arg ver "$CUSTOM_VERSION" \
    --arg uptime "$uptime" \
    --arg total_khs "$totalHr" \
    --arg hs_units "p/s" \
    --arg algo "$algo" \
    --argjson hs "$hr_json" \
    --argjson fan "$fan_json" \
    --argjson temp "$temp_json" \
    --argjson bus_numbers "$busid_json" \
    '{ver: $ver, uptime: $uptime, total_khs: $total_khs, hs: $hs, hs_units: $hs_units, algo: $algo, fan: $fan, temp: $temp, bus_numbers: $bus_numbers}')

# Affichage pour HiveOS
echo "$stats"
