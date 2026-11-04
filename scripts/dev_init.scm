;; ====================================================================
;; dev_init.scm - Steel REPL 专属开发环境自动初始化脚本
;; 启动 REPL 时自动加载:
;; 1. Rust 宿主模拟桩 (engine:* 原生函数)
;; 2. main.scm 游戏主脚本 (包含 task0/task1 等所有子模块)
;; ====================================================================

(load "mock_host.scm")
(load "main.scm")

(displayln "\x1b;[32m🚀 [Dev] 宿主桩与 main.scm 已自动预加载完成！\x1b;[0m")
(displayln "\x1b;[90m提示: 可直接输入 (engine:on-init) 或测试业务函数\x1b;[0m\n")
