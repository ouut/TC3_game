;; 1. 自定义工具注册表
(define *mcp-tools* (hash))
(define (mcp:def-tool name desc schema handler)
  (set! *mcp-tools* (hash-insert *mcp-tools* name (hash "desc" desc "schema" schema "handler" handler))))
;; 2. 宿主回调钩子（当 MCP 收到对自定义工具的调用时触发）
(define (engine:on-mcp-call tool-name args-hash)
  (if (hash-contains? *mcp-tools* tool-name)
      (let ((tool (hash-ref *mcp-tools* tool-name)))
        ((hash-ref tool "handler") args-hash))
      (hash "error" (string-append "未找到工具: " tool-name))))


(provide *mcp-tools* mcp:def-tool engine:on-mcp-call)