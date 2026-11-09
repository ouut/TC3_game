;; ====================================================================
;; mcp_help.scm - MCP 工具注册与分发助手
;; ====================================================================

;; 1. 自定义工具注册表
(define *mcp-tools* (hash))

(define (mcp:def-tool name desc schema handler)
  (set! *mcp-tools* (hash-insert *mcp-tools* name (hash "desc" desc "schema" schema "handler" handler))))

;; 2. 宿主获取工具列表回调
(define (engine:mcp-tools)
  *mcp-tools*)

;; 3. 宿主调用工具回调
(define (engine:on-mcp-call tool-name args-hash)
  (if (hash-contains? *mcp-tools* tool-name)
      (let ((tool (hash-ref *mcp-tools* tool-name)))
        ((hash-ref tool "handler") args-hash))
      (hash "error" (string-append "未找到工具: " tool-name))))

(provide *mcp-tools* mcp:def-tool engine:mcp-tools engine:on-mcp-call)
