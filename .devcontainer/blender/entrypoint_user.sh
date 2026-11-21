#!/usr/bin/env bash
set -e

# WAYVNC_PORT is the externally published WebSocket port served by websockify
# (see ~/.config/sway/config). wayvnc itself listens on 127.0.0.1:5901 only.
export WAYVNC_PORT="${WAYVNC_PORT:-5900}"

CURRENT_DIR="$(dirname $0)"
. "$CURRENT_DIR/reload.sh"

# start wayland session for running browser instances
sway &
sway_pid=$!

# wait for sway to start and get the display socket
# `find`コマンドで、$XDG_RUNTIME_DIR/wayland-*の中から最初の1つを取得し、WAYLAND_DISPLAYに代入する。
echo "Waiting for sway to start..."
retry_count=0
max_retries=5
set +e
while [ -z "$WAYLAND_DISPLAY" ] && [ $retry_count -lt $max_retries ]; do
    sleep 1
    WAYLAND_DISPLAY=$(find "$XDG_RUNTIME_DIR"/wayland-* | head -n 1)
    ((retry_count++))
done
set -e
if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "fatal: Sway not started! (display socket not found in $XDG_RUNTIME_DIR/wayland-*)"
    exit 1
fi
echo "Found WAYLAND_DISPLAY socket: $WAYLAND_DISPLAY"
export WAYLAND_DISPLAY

# sway/config で定義されている環境変数を読み込む。
source /tmp/sway-env
## Sway のセッションが開始されるまで待機する。
while [ "$(swaymsg -t get_seats | jq 'length')" -le 1 ]; do
    sleep 1
done

# リポジトリのホットリロード
start_hotreload

# blender の起動
export BLENDER_CUSTOM_SPLASH=/workspaces/development/.devcontainer/blender/sway/splash.png
user_exit=0
while :; do
    if [ "$user_exit" -eq 1 ]; then
        break
    fi
    blender/blender &>> development/output-${SERVICE_NAME}.log &
    blender_pid=$!
    wait $blender_pid
done

# 終了時の処理の定義
cleanup() {
    user_exit=1
    echo "Stopping processes..."
    kill -TERM $watch_pid 2>/dev/null
    while ps -p $watch_pid > /dev/null 2>&1; do sleep 1; done
    kill -TERM $blender_pid 2>/dev/null
    while ps -p $blender_pid > /dev/null 2>&1; do sleep 1; done
    kill $sway_pid 2>/dev/null
    while ps -p $sway_pid > /dev/null 2>&1; do sleep 1; done
    echo "Done."
}

# プロセスの終了(TERM)やINT(CTRL+C)を検知して、cleanup関数を実行する。
trap cleanup TERM INT

# `wait`コマンドで、blenderのプロセスが終了するまで待つ。
wait $blender_pid
if [ $user_exit -ne 1 ]; then
    echo "Blender process completed."
    kill $watch_pid 2>/dev/null
    while ps -p $watch_pid > /dev/null 2>&1; do sleep 1; done
    kill $sway_pid 2>/dev/null
    while ps -p $sway_pid > /dev/null 2>&1; do sleep 1; done
    echo "Done."
fi
wait $watch_pid
wait $sway_pid
