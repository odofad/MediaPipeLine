#!/bin/bash
# Install MediaPipeLine from this master tree into the system locations.
# Edit scripts here. Edit tunables in /etc/mediapipeline/pipe.conf.
# Do not edit the copies under /usr/local/bin.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="${ROOT}/bin"
UNIT_SRC="${ROOT}/systemd"
PREFIX="/usr/local/bin"
UNIT_DEST="/etc/systemd/system"
CONF_SRC="${ROOT}/pipe.conf"
CONF_DIR="/etc/mediapipeline"
STAMP_DIR="/var/lib/MediaPipeLine"
STAMP_BIN="${STAMP_DIR}/bin.list"
STAMP_UNIT="${STAMP_DIR}/unit.list"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ${ROOT}/install.sh" >&2
  exit 1
fi

os_id=""
os_version=""
if [[ ! -r /etc/os-release ]]; then
  echo "This installer is for Ubuntu Server 26.04. /etc/os-release is missing." >&2
  exit 1
fi
while IFS= read -r line || [[ -n "${line}" ]]; do
  case "${line}" in
    ID=*) os_id="${line#ID=}"; os_id="${os_id//\"/}" ;;
    VERSION_ID=*) os_version="${line#VERSION_ID=}"; os_version="${os_version//\"/}" ;;
  esac
done < /etc/os-release
if [[ "${os_id}" != "ubuntu" || "${os_version}" != "26.04" ]]; then
  echo "This installer is for Ubuntu Server 26.04. This machine is ${os_id:-unknown} ${os_version:-unknown}." >&2
  exit 1
fi

echo "installing ffmpeg, exiftool, and mediainfo from Ubuntu"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ffmpeg libimage-exiftool-perl mediainfo
if ! /usr/bin/ffprobe -version >/dev/null 2>&1; then
  echo "/usr/bin/ffprobe did not start. A library in /usr/local/lib may be hiding the Ubuntu package." >&2
  exit 1
fi
if ! /usr/bin/exiftool -ver >/dev/null 2>&1; then
  echo "/usr/bin/exiftool did not start." >&2
  exit 1
fi
if ! /usr/bin/mediainfo --Version >/dev/null 2>&1; then
  echo "/usr/bin/mediainfo did not start." >&2
  exit 1
fi
echo "ffprobe, exiftool, and mediainfo start"

systemctl_bin=systemctl
[[ -x /usr/bin/systemctl ]] && systemctl_bin=/usr/bin/systemctl

mkdir -p "${STAMP_DIR}" "${PREFIX}" "${UNIT_DEST}" "${CONF_DIR}" /var/log/mediapipeline
touch "${STAMP_BIN}" "${STAMP_UNIT}"

if [[ ! -f "${CONF_SRC}" ]]; then
  echo "Missing ${CONF_SRC}" >&2
  exit 1
fi
install -m 644 "${CONF_SRC}" "${CONF_DIR}/pipe.conf.default"
if [[ ! -f "${CONF_DIR}/pipe.conf" ]]; then
  install -m 644 "${CONF_SRC}" "${CONF_DIR}/pipe.conf"
  echo "installed ${CONF_DIR}/pipe.conf"
fi
echo "updated ${CONF_DIR}/pipe.conf.default"

conf_get() {
  local key="$1" line val
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" =~ ^[[:space:]]*${key}[[:space:]]*=(.*)$ ]] || continue
    val="${BASH_REMATCH[1]}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    printf '%s' "${val}"
    return 0
  done < "${CONF_DIR}/pipe.conf"
  return 1
}

conf_set() {
  local key="$1" value="$2" tmp found=0 line
  tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^[[:space:]]*${key}[[:space:]]*= ]]; then
      printf '%s = %s\n' "${key}" "${value}" >> "${tmp}"
      found=1
    else
      printf '%s\n' "${line}" >> "${tmp}"
    fi
  done < "${CONF_DIR}/pipe.conf"
  if [[ "${found}" -eq 0 ]]; then
    printf '%s = %s\n' "${key}" "${value}" >> "${tmp}"
  fi
  cat "${tmp}" > "${CONF_DIR}/pipe.conf"
  rm -f "${tmp}"
}

ask_path() {
  local prompt="$1" default="$2" answer=""
  default="${default%/}"
  if [[ -t 0 ]]; then
    read -r -p "${prompt} [${default}]: " answer || answer=""
  else
    read -r answer || answer=""
    echo "${prompt} [${default}]: ${answer:-${default}}" >&2
  fi
  answer="${answer#"${answer%%[![:space:]]*}"}"
  answer="${answer%"${answer##*[![:space:]]}"}"
  answer="${answer%/}"
  [[ -n "${answer}" ]] || answer="${default}"
  if [[ "${answer}" != /* || "${answer}" == *[*?]* ]]; then
    echo "Need an absolute path, with no * or ?: ${answer}" >&2
    exit 1
  fi
  printf '%s' "${answer}"
}

archive_default="$(conf_get logged || true)"
archive_default="${archive_default%/*}"
[[ -n "${archive_default}" ]] || archive_default="/var/lib/mediapipeline/archive"
output_default="$(conf_get hevc_root || true)"
[[ -n "${output_default}" ]] || output_default="/var/lib/mediapipeline/encode"

echo "Archive root is the input. The numbered folders are created under it."
echo "Encode output is where the encoder will write. Nothing encodes yet."
archive="$(ask_path "Archive root" "${archive_default}")"
output="$(ask_path "Encode output" "${output_default}")"

default_user="${SUDO_USER:-}"
if [[ -z "${default_user}" ]]; then
  default_user="$(logname 2>/dev/null || true)"
fi
[[ -n "${default_user}" ]] || default_user="$(id -un)"
if [[ -t 0 ]]; then
  read -r -p "Run as [${default_user}]: " run_user || run_user=""
else
  read -r run_user || run_user=""
  echo "Run as [${default_user}]: ${run_user:-${default_user}}" >&2
fi
run_user="${run_user#"${run_user%%[![:space:]]*}"}"
run_user="${run_user%"${run_user##*[![:space:]]}"}"
[[ -n "${run_user}" ]] || run_user="${default_user}"
if ! getent passwd "${run_user}" >/dev/null; then
  echo "No such user: ${run_user}" >&2
  exit 1
fi
run_group="$(id -gn "${run_user}")"

if [[ -t 0 ]]; then
  read -r -p "Enable the detection timer now? [y/N]: " enable_timer || enable_timer=""
else
  read -r enable_timer || enable_timer=""
  echo "Enable the detection timer now? [y/N]: ${enable_timer:-n}" >&2
fi
enable_timer="${enable_timer,,}"
case "${enable_timer}" in
  y|yes) enable_timer=1 ;;
  *) enable_timer=0 ;;
esac

for name in 2.Logged 2.1.Relog 2.2.Recovery 2.3.Error 3.Convert 4.Converted; do
  mkdir -p "${archive}/${name}"
  echo "folder ${archive}/${name}"
done
mkdir -p "${output}"
echo "folder ${output}"
chown "${run_user}:${run_group}" "${output}"
for name in 2.Logged 2.1.Relog 2.2.Recovery 2.3.Error 3.Convert 4.Converted; do
  chown "${run_user}:${run_group}" "${archive}/${name}"
done

conf_set logged "${archive}/2.Logged"
conf_set relog "${archive}/2.1.Relog"
conf_set recovery "${archive}/2.2.Recovery"
conf_set error "${archive}/2.3.Error"
conf_set convert "${archive}/3.Convert"
conf_set converted "${archive}/4.Converted"
conf_set hevc_root "${output}"
chown -R "${run_user}:${run_group}" "${CONF_DIR}" /var/log/mediapipeline

missing=$(awk -F= '
  FNR==NR {
    if ($0 !~ /^[[:space:]]*#/ && $0 ~ /=/) {
      k=$1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      if (k != "") have[k]=1
    }
    next
  }
  $0 !~ /^[[:space:]]*#/ && $0 ~ /=/ {
    k=$1
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
    if (k != "" && !(k in have)) print k
  }
' "${CONF_DIR}/pipe.conf" "${CONF_SRC}")
if [[ -n "${missing}" ]]; then
  echo "live conf is missing keys that are in pipe.conf.default:"
  printf '  %s\n' ${missing}
  echo "Add them by hand. Folder paths are the only lines this install writes."
fi

mapfile -t old_bins < "${STAMP_BIN}"
mapfile -t old_units < "${STAMP_UNIT}"

new_bins=()
bin_list="$(mktemp)"
if [[ -d "${BIN_SRC}" ]]; then
  find "${BIN_SRC}" -maxdepth 1 -type f -printf '%f\n' | sort > "${bin_list}"
  while IFS= read -r name; do
    [[ -z "${name}" || "${name}" == .* ]] && continue
    install -o "${run_user}" -g "${run_group}" -m 755 "${BIN_SRC}/${name}" "${PREFIX}/${name}"
    echo "installed ${PREFIX}/${name} as ${run_user}"
    new_bins+=("${name}")
  done < "${bin_list}"
fi
rm -f "${bin_list}"

new_units=()
unit_list="$(mktemp)"
if [[ -d "${UNIT_SRC}" ]]; then
  find "${UNIT_SRC}" -maxdepth 1 -type f -printf '%f\n' | sort > "${unit_list}"
  while IFS= read -r name; do
    [[ -z "${name}" || "${name}" == .* ]] && continue
    install -m 644 "${UNIT_SRC}/${name}" "${UNIT_DEST}/${name}"
    echo "installed ${UNIT_DEST}/${name}"
    new_units+=("${name}")
  done < "${unit_list}"
fi
rm -f "${unit_list}"

drop_dir="${UNIT_DEST}/mediapipeline-detect.service.d"
mkdir -p "${drop_dir}"
cat > "${drop_dir}/run.conf" <<EOF
[Unit]
RequiresMountsFor=${archive}/2.Logged

[Service]
User=${run_user}
Group=${run_group}
EOF
echo "timer runs as ${run_user}"

removed=0
for name in "${old_bins[@]}"; do
  [[ -z "${name}" ]] && continue
  keep=0
  for now in "${new_bins[@]}"; do
    [[ "${now}" == "${name}" ]] && keep=1 && break
  done
  if [[ "${keep}" -eq 0 && -f "${PREFIX}/${name}" ]]; then
    rm -f "${PREFIX}/${name}"
    echo "removed ${PREFIX}/${name}"
    removed=1
  fi
done

for name in "${old_units[@]}"; do
  [[ -z "${name}" ]] && continue
  keep=0
  for now in "${new_units[@]}"; do
    [[ "${now}" == "${name}" ]] && keep=1 && break
  done
  if [[ "${keep}" -eq 0 && -f "${UNIT_DEST}/${name}" ]]; then
    "$systemctl_bin" disable --now "${name}" >/dev/null 2>&1 || true
    rm -f "${UNIT_DEST}/${name}"
    echo "removed ${UNIT_DEST}/${name}"
    removed=1
  fi
done

printf '%s\n' "${new_bins[@]}" > "${STAMP_BIN}"
printf '%s\n' "${new_units[@]}" > "${STAMP_UNIT}"

if command -v "$systemctl_bin" >/dev/null 2>&1; then
  "$systemctl_bin" daemon-reload
  if [[ "${enable_timer}" -eq 1 ]]; then
    "$systemctl_bin" enable --now mediapipeline-detect.timer
    echo "enabled mediapipeline-detect.timer"
  else
    echo "timer not enabled. An already enabled timer is left as it is."
  fi
elif [[ "${enable_timer}" -eq 1 ]]; then
  echo "timer not enabled: systemctl not found" >&2
else
  echo "timer not enabled."
fi
echo "Tunables live in ${CONF_DIR}/pipe.conf. A later install asks again and rewrites only the folder paths, the run user, and the timer switch."
echo "Status screen: ${PREFIX}/mediapipeline-status"
redline_bin="$(conf_get redline || true)"
[[ -n "${redline_bin}" ]] || redline_bin="REDline"
if ! command -v "${redline_bin}" >/dev/null 2>&1; then
  echo "warning: ${redline_bin} is not on PATH. RED picture fields need it. A .r3d without it is still carded. The codec line is REDCODE."
fi
