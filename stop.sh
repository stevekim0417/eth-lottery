#!/bin/bash
PORT=8080
DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/.server.pid"

# PID 파일로 종료 시도
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "서버 종료 (PID: $PID)"
    fi
    rm -f "$PID_FILE"
fi

# 포트에 남아있는 프로세스 정리
if lsof -ti:$PORT > /dev/null 2>&1; then
    lsof -ti:$PORT | xargs kill 2>/dev/null
    echo "포트 $PORT 정리 완료"
fi

echo "서버가 중지되었습니다."
