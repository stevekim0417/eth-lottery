#!/bin/bash
PORT=8080
DIR="$(cd "$(dirname "$0")" && pwd)"

# 이미 실행 중인지 확인
if lsof -ti:$PORT > /dev/null 2>&1; then
    echo "이미 포트 $PORT에서 서버가 실행 중입니다."
    echo "http://localhost:$PORT/index.html"
    exit 0
fi

# 서버 백그라운드 실행
cd "$DIR"
python3 -m http.server $PORT > /dev/null 2>&1 &
echo $! > "$DIR/.server.pid"

echo "서버 시작 (PID: $!, 포트: $PORT)"
echo "http://localhost:$PORT/index.html"
