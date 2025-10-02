#!/bin/bash
set -e

function NeedToInstall() {
  local ver=$(apt-cache policy "$1" | grep Installed | sed 's/Installed://; s/\s*//')
  if [[ $2 ]]; then
    local majorVer=$(echo "$ver" | cut -d- -f1)
    if (( $(echo "$majorVer > $2" | bc -l) )); then
      echo 0
    else
      echo 1
    fi
  else
    [[ $ver && $ver != '(none)' ]] && echo 0 || echo 1
  fi
}

if [[ $(NeedToInstall libc6 "2.32") -eq 1 ]]; then
  echo -e "> Обновление libc6"
  echo "deb http://cz.archive.ubuntu.com/ubuntu jammy main" >> /etc/apt/sources.list
  apt update
  apt install libc6 -yqq --no-install-recommends
else
  echo -e "[✔] libc6 уже установлена"
fi

# Обновление для поддержки бинарников из noble (libstdc++6 и libjansson4)
echo "[*] Добавление временного источника Ubuntu Noble (24.04)"
apt install -y dirmngr gnupg gpg
echo "deb [signed-by=/usr/share/keyrings/ubuntu-noble.gpg] http://archive.ubuntu.com/ubuntu noble main universe" \
  > /etc/apt/sources.list.d/noble-temp.list

gpg --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
gpg --export 3B4FE6ACC0B21F32 | tee /usr/share/keyrings/ubuntu-noble.gpg > /dev/null
gpg --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C
gpg --export 871920D1991BC93C | tee -a /usr/share/keyrings/ubuntu-noble.gpg > /dev/null

echo "[*] Установка libjansson4 и libstdc++6 из noble"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y -t noble libjansson4 libstdc++6

# Очистка
rm /etc/apt/sources.list.d/noble-temp.list
apt update

# Проверка libcublas
if ldconfig -p | grep -q libcublas.so.12; then
  echo "[✔] Уже установлено: libcublas.so.12"
  exit 0
fi

# CUDA
UBU_VERSION=$(lsb_release -sr)
case "$UBU_VERSION" in
  "20.04") CUDA_REPO="ubuntu2004" ;;
  "22.04") CUDA_REPO="ubuntu2204" ;;
  "24.04") CUDA_REPO="ubuntu2404" ;;
  *)
    echo "[!] Скрипт поддерживает только Ubuntu 20.04 / 22.04 / 24.04 (а не $UBU_VERSION)"
    exit 1
    ;;
esac

echo "[*] Установка зависимостей CUDA"
apt install -y wget ca-certificates gnupg lsb-release curl --allow-downgrades

PIN_URL="https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_REPO}/x86_64/cuda-${CUDA_REPO}.pin"
wget "$PIN_URL" -O /etc/apt/preferences.d/cuda-repository-pin-600

curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_REPO}/x86_64/3bf863cc.pub \
  | gpg --dearmor | tee /usr/share/keyrings/cuda-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_REPO}/x86_64/ /" \
  > /etc/apt/sources.list.d/cuda.list

apt update

if [[ "$UBU_VERSION" == "24.04" ]]; then
  apt install -y libcublas12 libcudart12
else
  apt install -y cuda-libraries-12-4
fi

echo "[*] Проверка установки libcublas.so.12"
if ldconfig -p | grep -q libcublas.so.12; then
  echo "[✔] Успешно установлено: libcublas.so.12"
else
  echo "[!] Установка libcublas не удалась"
  exit 1
fi
