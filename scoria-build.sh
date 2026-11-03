#!/usr/bin/env bash
# Build Scoria (our MuseScore Studio fork) on Void Linux.
#
#   ./scoria-build.sh deps     # once: install system libraries (asks for sudo)
#   ./scoria-build.sh          # configure + build + install into ./build.install (gentle; JOBS=N to change)
#   ./scoria-build.sh run      # launch it
#   ./scoria-build.sh check    # show what this PC can handle + recommended JOBS
set -euo pipefail
cd "$(dirname "$0")"

QT_DIR="${QT_DIR:-$HOME/Qt/6.11.2/gcc_64}"   # installed with aqtinstall (Qt 6.11.2, same as upstream CI)
BUILD=build.release
INSTALL="$PWD/build.install"

# CPU package temperature in °C (empty if no sensor).
cpu_temp() {
    local z
    for z in /sys/class/thermal/thermal_zone*; do
        if [ "$(cat "$z/type" 2>/dev/null)" = "x86_pkg_temp" ]; then
            echo $(( $(cat "$z/temp") / 1000 )); return
        fi
    done
    for z in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$z/name" 2>/dev/null)" = "coretemp" ]; then
            echo $(( $(cat "$z/temp1_input") / 1000 )); return
        fi
    done
}

HOT=${HOT:-85}    # pause the build at this temperature
COOL=${COOL:-70}  # resume once it drops to this

# Run a command, pausing it (SIGSTOP) whenever the CPU gets too hot.
run_with_heat_guard() {
    setsid "$@" &
    local pid=$! paused=0 t
    trap 'kill -CONT -- -$pid 2>/dev/null; kill -TERM -- -$pid 2>/dev/null; exit 130' INT TERM
    while kill -0 "$pid" 2>/dev/null; do
        t=$(cpu_temp)
        if [ -n "$t" ]; then
            if (( paused == 0 && t >= HOT )); then
                kill -STOP -- -"$pid" 2>/dev/null && paused=1
                echo ">> CPU at ${t}°C: pausing the build to cool down (resumes at ${COOL}°C)"
            elif (( paused == 1 && t <= COOL )); then
                kill -CONT -- -"$pid" 2>/dev/null && paused=0
                echo ">> CPU back to ${t}°C: resuming"
            fi
        fi
        sleep 2
    done
    trap - INT TERM
    wait "$pid"
}

# How many compile jobs this machine can take right now, while staying usable.
# Each MuseScore C++ compile can use ~1.5 GB RAM; leave 4 GB + half the CPU for the desktop.
recommend_jobs() {
    local cores avail_mb load by_cpu by_ram jobs
    cores=$(nproc)
    avail_mb=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
    load=$(awk '{print int($1 + 0.5)}' /proc/loadavg)
    by_cpu=$(( (cores / 2) - load ))
    by_ram=$(( (avail_mb - 4096) / 1536 ))
    jobs=$(( by_cpu < by_ram ? by_cpu : by_ram ))
    (( jobs < 1 )) && jobs=1
    echo "$jobs"
}

case "${1:-build}" in
deps)
    # Void equivalents of upstream's apt list (muse/buildscripts/ci/linux/setup.sh),
    # plus what Qt's prebuilt binaries need at runtime (Kerberos, xcb, xkbcommon).
    pkgs=(
        cmake ninja git pkg-config
        alsa-lib-devel libsndfile-devel cups-devel
        Vulkan-Headers vulkan-loader-devel MesaLib-devel
        ffmpeg6-devel pulseaudio-devel pipewire-devel
        freetype-devel fontconfig-devel harfbuzz-devel
        libxkbcommon-devel libxkbcommon-x11 xcb-util-cursor xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil
        mit-krb5-libs
    )
    sudo xbps-install -S >/dev/null
    todo=()
    for p in "${pkgs[@]}"; do
        if xbps-query "$p" >/dev/null 2>&1; then
            continue                       # already installed
        elif xbps-query -R "$p" >/dev/null 2>&1; then
            todo+=("$p")
        else
            echo "!! not in Void repos (tell Claude): $p"
        fi
    done
    if [ ${#todo[@]} -eq 0 ]; then
        echo "All dependencies already installed."
    else
        echo "Installing: ${todo[*]}"
        sudo xbps-install -y "${todo[@]}"
    fi
    ;;
build)
    [ -d "$QT_DIR" ] || { echo "Qt not found at $QT_DIR"; exit 1; }
    bash patches/apply.sh
    cmake -S . -B "$BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_PREFIX_PATH="$QT_DIR" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL"
    # Gentle by default: job count from free RAM/CPU (see `check`), lowest CPU + disk priority.
    # Want it faster? JOBS=24 ./scoria-build.sh
    jobs="${JOBS:-$(recommend_jobs)}"
    echo "Building with $jobs jobs (low priority). Ctrl+C is safe: rerun to continue where it stopped."
    echo "Heat guard: pauses at ${HOT}°C, resumes at ${COOL}°C (now: $(cpu_temp)°C)."
    run_with_heat_guard nice -n 19 ionice -c 3 cmake --build "$BUILD" -j"$jobs"
    cmake --install "$BUILD"
    echo "Built. Run: ./scoria-build.sh run"
    ;;
check)
    cores=$(nproc)
    total_gb=$(awk '/MemTotal/ {printf "%.1f", $2/1048576}' /proc/meminfo)
    avail_gb=$(awk '/MemAvailable/ {printf "%.1f", $2/1048576}' /proc/meminfo)
    read -r l1 l5 _ < /proc/loadavg
    cpu=$(awk -F: '/model name/ {gsub(/^ +/, "", $2); print $2; exit}' /proc/cpuinfo)
    rec=$(recommend_jobs)
    echo "CPU:        $cpu ($cores threads)"
    echo "RAM:        $avail_gb GB free of $total_gb GB"
    echo "Load now:   $l1 (1 min avg), $l5 (5 min avg)"
    echo "Disk free:  $(df -h . | awk 'NR==2 {print $4}') here (a full build needs ~15 GB)"
    t=$(cpu_temp)
    echo "CPU temp:   ${t:-unknown}°C   (build pauses at ${HOT}°C, resumes at ${COOL}°C)"
    if [ -n "$t" ] && (( t >= 60 )); then
        echo "            Already warm. No CPU fan? Use JOBS=2 and expect lots of pauses."
    fi
    echo
    echo "Recommended: $rec jobs  (what './scoria-build.sh' uses by default right now)"
    echo "  gentler:   JOBS=$(( rec / 2 > 0 ? rec / 2 : 1 )) ./scoria-build.sh"
    echo "  max speed: JOBS=$cores ./scoria-build.sh   (PC will be sluggish)"
    ;;
run)
    if [ ! -d "$INSTALL/bin" ]; then
        echo "Scoria isn't built yet. Run these first:"
        echo "  ./scoria-build.sh deps   # once, installs system libraries"
        echo "  ./scoria-build.sh        # builds Scoria (30-60 min the first time)"
        exit 1
    fi
    exe=$(find "$INSTALL/bin" -maxdepth 1 -type f -executable | head -1)
    LD_LIBRARY_PATH="$QT_DIR/lib:${LD_LIBRARY_PATH:-}" "$exe"
    ;;
*)
    echo "usage: $0 [deps|build|run|check]"; exit 1 ;;
esac
