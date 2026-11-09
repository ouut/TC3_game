#!/usr/bin/env python3
import sys
import json
import urllib.request

MCP_URL = "http://127.0.0.1:8082/mcp"

def call_mcp(method, name, args):
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": method,
        "params": {"name": name, "arguments": args}
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(MCP_URL, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=3) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            if "result" in res and "content" in res["result"]:
                txt = res["result"]["content"][0]["text"]
                return json.loads(txt)
    except Exception as e:
        return {"error": str(e)}
    return {}

def main():
    print("\033[2J\033[H", end="") # Clear terminal
    res = call_mcp("tools/call", "game_command", {"command": "help"})
    if "ascii_screen" in res:
        print(res["ascii_screen"])
    else:
        print("无法连接到服务端 (8082 端口)，请确认已启动: ./server --scripts-dir scripts --mcp-port 8082")
        return

    print("\n\033[36;1m[终端试玩已连接]\033[0m 直接输入游戏指令 (如 m 0 1, c 0, eat 1, buy tree, recipes)，回车单步推演，输入 q 退出:")
    while True:
        try:
            cmd = input("\nTextlands > ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if cmd.lower() in ("q", "quit", "exit"):
            break
        if not cmd:
            cmd = "(ping)"
        res = call_mcp("tools/call", "game_command", {"command": cmd})
        print("\033[2J\033[H", end="") # Clear screen
        if "ascii_screen" in res:
            print(res["ascii_screen"])
        else:
            print(res)

if __name__ == "__main__":
    main()
