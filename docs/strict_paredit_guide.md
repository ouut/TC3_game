# VS Code 网页版 Strict Paredit 快捷键手册与肌肉记忆实战指南

> **适用环境**：VS Code Web / Code-Server（无浏览器热键冲突，正交几何键位）  
> **核心法则**：全套快捷键**仅使用修饰键 + 方向键 / 回车 / 退格 / [ / ( **，手不离主键盘区，闭眼盲操。

---

## 键盘符号与按键对照 (Windows / Linux vs macOS)

在 macOS 上，VS Code 的修饰键映射如下：
* **`Alt`** $\rightarrow$ **`Option (⌥)`**
* **`Ctrl`** $\rightarrow$ **`Control (⌃)`**
* **`Shift`** $\rightarrow$ **`Shift (⇧)`**
* **`Enter`** $\rightarrow$ **`Return (↩)`**
* **`Backspace`** $\rightarrow$ **`Delete (⌫)`**

```
                     【左手修饰键】                    【右手物理键】
              Win/Linux        macOS
           ┌─────────────┬─────────────┐          ┌──────────────────┐
           │ Alt         │ Option (⌥)  │    +     │ ↑ / ↓ (垂直缩放) │
           │ Ctrl        │ Control (⌃) │          │ ← / → (水平跳转) │
           │ Shift       │ Shift (⇧)   │          │ Enter / Backspace│
           │             │             │          │ [  /  (  (结构包)│
           └─────────────┴─────────────┘          └──────────────────┘
```

---

## 一、 快捷键全景图（按 Scheme 日常使用频率排序）

| 频级 / 占比 | Windows / Linux 快捷键 | macOS 快捷键 | 命令名称 | 动作与视觉效果 | 核心使用场景 |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **⭐⭐⭐⭐⭐<br>(45%)** | **`Alt + ↑`** | **`⌥ + ↑`** | **Expand S-Exp**<br>(扩选表达式) | 光标在括号内，按一下自动**严丝合缝选中当前 `(...)`**，连按向外扩大一层括号。 | 配合执行求值，彻底消灭用鼠标框选代码。 |
| **⭐⭐⭐⭐⭐<br>(45%)** | **`Alt + Enter`**<br>*(或 `Ctrl+Enter`)* | **`⌥ + Return`**<br>*(或 `⌘+Return`)* | **Run Selected**<br>(发射求值) | 将当前选中的代码**直接发送到右侧 Steel REPL 运行**并吐出结果。 | **极速连招**：左手按住 `Alt` / `Option` 不松，右手按 `↑` 紧接着按 `Enter` / `Return`。 |
| **⭐⭐⭐⭐<br>(25%)** | **`Alt + Shift + 9`**<br>*(即 `Alt + (` )* | **`⌥ + ⇧ + 9`**<br>*(即 `⌥ + (` )* | **Wrap Around ()**<br>(圆括号包裹) | `foo` $\rightarrow$ `(foo)`<br>将光标所在的变量或选中的表达式用圆括号 `()` 包裹起来。 | **极高频！** 快速将变量转为函数调用，如 `cards` $\rightarrow$ `(car cards)`。 |
| **⭐⭐⭐⭐<br>(25%)** | **`Alt + [`** | **`⌥ + [`** | **Wrap Around []**<br>(方括号包裹) | `x 10` $\rightarrow$ `[x 10]`<br>用方括号 `[]` 包裹当前选区。 | **极高频！** 写 Scheme 的 `let` 局部绑定对、`cond` 条件分支对。 |
| **⭐⭐⭐⭐<br>(20%)** | **`Alt + Shift + →`** | **`⌥ + ⇧ + →`** | **Slurp Forward**<br>(向右吞噬) | `(a b) c` $\rightarrow$ `(a b c)`<br>右括号向右跨越一个元素，将外部元素吸入括号内。 | 补写函数参数、包裹后续表达式。 |
| **⭐⭐⭐⭐<br>(20%)** | **`Alt + Shift + ←`** | **`⌥ + ⇧ + ←`** | **Barf Forward**<br>(向左吐出) | `(a b c)` $\rightarrow$ `(a b) c`<br>右括号向左收缩，把末尾元素踢出括号。 | 括号包多了、把错误放进括号的参数踢出。 |
| **⭐⭐⭐⭐<br>(15%)** | **`Ctrl + → / ←`** | **`⌃ + → / ←`** | **Forward / Back Sexp**<br>(跨越表达式) | 光标一次性**跳过整组 `(...)`** 或单个变量，而不是按字符移动。 | 在复杂的嵌套参数之间快速跳跃。 |
| **⭐⭐⭐⭐<br>(15%)** | **`Alt + ↓`** | **`⌥ + ↓`** | **Contract Selection**<br>(收缩选区) | 选区缩小一级括号（`Alt + ↑` 选多了时向内回退）。 | 选区精确定位。 |
| **⭐⭐⭐<br>(10%)** | **`Alt + Shift + ↑`** | **`⌥ + ⇧ + ↑`** | **Select Top Form**<br>(选中顶层定义) | 无论光标在函数内部多深，一键选中最外层整个 `(define ...)`。 | 重新编译整个函数、复制整段定义。 |
| **⭐⭐⭐<br>(10%)** | **`Alt + Shift + ↓`** | **`⌥ + ⇧ + ↓`** | **Splice Sexp**<br>(脱壳 / 解包) | `(let (...) (expr))` $\rightarrow$ `(expr)`<br>剥除外层括号，保留内部所有元素。 | 重构时拆掉 `let`、`cond` 或辅助包装函数。 |
| **⭐⭐⭐<br>(10%)** | **`Ctrl + ↓ / ↑`** | **`⌃ + ↓ / ↑`** | **Down / Up Sexp**<br>(深度穿透) | 钻入当前括号内部最左侧 / 跳出到外层括号前置位。 | 快速进入函数体第一行，或跳出局部作用域。 |
| **⭐⭐<br>(5%)** | **`Shift + Enter`** | **`⇧ + Return`** | **Indent S-Exp**<br>(语法树缩进排版) | 智能对齐当前 S 表达式的缩进格式。 | 粘贴代码后快速恢复严整格式。 |
| **⭐⭐<br>(5%)** | **`Ctrl + Delete`** | **`⌃ + Delete`** | **Kill Sexp Forward**<br>(向后整块删除) | 删掉光标右侧的一整个完整的子表达式。 | 快速清除冗余分支或调试代码。 |
| **⭐⭐<br>(5%)** | **`Ctrl + Backspace`**| **`⌃ + ⌫`** | **Kill Sexp Backward**<br>(向前整块删除) | 删掉光标左侧的一整个完整的子表达式。 | 快速清除上一项参数。 |
| **⭐<br>(2%)** | **`Ctrl + Alt + →`** | **`⌃ + ⌥ + →`** | **Transpose**<br>(相邻参数对调) | `(equal? a b)` $\rightarrow$ `(equal? b a)`<br>光标两侧的参数直接互换位置。 | 修正参数顺序颠倒问题。 |
| **⭐<br>(2%)** | **`Ctrl + Alt + ↓`** | **`⌃ + ⌥ + ↓`** | **Split Sexp**<br>(一分为二) | `(a b \| c d)` $\rightarrow$ `(a b) (c d)`<br>在光标处将一个列表切开成两个同级列表。 | 拆分超长列表或重构结构。 |
| **⭐<br>(1%)** | **`Ctrl+Alt+Shift+←`** | **`⌃ + ⌥ + ⇧ + ←`** | **Slurp Backward**<br>(向前吞噬) | `a (b c)` $\rightarrow$ `(a b c)`<br>左括号向左延伸，吸入左侧元素。 | 头部包裹。 |
| **⭐<br>(1%)** | **`Ctrl+Alt+Shift+→`** | **`⌃ + ⌥ + ⇧ + →`** | **Barf Backward**<br>(向前吐出) | `(a b c)` $\rightarrow$ `a (b c)`<br>左括号向右缩回，将第一项踢出到括号外。 | 头部剔除。 |

---

## 二、 肌肉记忆通关练习题（Hands-on Exercises）

请新建一个空白测试文件（或在 `scripts/test_paredit.scm` 中），复制下面的题目代码，**严禁用鼠标与普通退格**，使用对应的 Paredit 快捷键完成挑战！

---

### 练习 1：极速求值（`Alt + ↑` $\rightarrow$ `Alt + Enter` | Mac: `⌥ + ↑` $\rightarrow$ `⌥ + Return`）
**目标**：光标停在数字 `2` 处，0.5 秒内将 `(+ 1 2)` 送入 REPL 计算出结果 `3`。
```scheme
;; 光标放在 2 后面:
(+ 1 2)
```
* **操作步骤**：
  1. 按 **`Alt + ↑`**（Mac: **`⌥ + ↑`**）：编辑器精准高亮 `(+ 1 2)`。
  2. 左手不松 `Alt` / `⌥`，右手直接敲 **`Enter`**（Mac: **`Return`**）！
  3. 右侧 REPL 吐出 `=> 3`。

---

### 练习 2：变量升格为函数调用 Wrap ()（`Alt + Shift + 9` | Mac: `⌥ + ⇧ + 9`）
**目标**：把变量 `cards` 瞬间用括号包起来，变成 `(cards)`，接着在前面补上 `length` 变成求长度。
```scheme
;; 初始状态 (光标停在 cards 单词内部):
(define num-cards cards)

;; 目标期望状态:
(define num-cards (length cards))
```
* **操作步骤**：
  1. 光标放在 `cards` 内部。
  2. 按一下 **`Alt + Shift + 9`**（Mac: **`⌥ + ⇧ + 9`**），`cards` 瞬间变成 `(cards)` 且光标停在最前面！
  3. 直接敲入 `length `，完成！**全程不需要手动去首尾加括号**。

---

### 练习 3：构建局部绑定对 Wrap []（`Alt + [` | Mac: `⌥ + [`）
**目标**：在写 `let*` 时，快速将变量名和表达式用方括号 `[]` 括起来。
```scheme
;; 初始状态 (选中或者光标在 len 10 处):
(let* (len 10)
  len)

;; 目标期望状态:
(let* ([len 10])
  len)
```
* **操作步骤**：
  1. 按 **`Alt + ↑`**（Mac: **`⌥ + ↑`**）选中 `len 10`。
  2. 按一下 **`Alt + [`**（Mac: **`⌥ + [`**），选中的两项瞬间被 `[...]` 规整包住！

---

### 练习 4：向右吞噬 Slurp（`Alt + Shift + →` | Mac: `⌥ + ⇧ + →`）
**目标**：将落单的 `(list-last cards)` 吸入外层 `string-append` 括号内。
```scheme
;; 初始状态 (光标在 "当前: " 后面):
(string-append "当前: ") (list-last cards)

;; 目标期望状态:
(string-append "当前: " (list-last cards))
```
* **操作步骤**：
  1. 光标停在 `(string-append ...)` 内部任意位置。
  2. 按一下 **`Alt + Shift + →`**（Mac: **`⌥ + ⇧ + →`**），右括号瞬间“跳过”并吞噬右侧表达式！

---

### 练习 5：向左吐出 Barf（`Alt + Shift + ←` | Mac: `⌥ + ⇧ + ←`）
**目标**：手滑把 `displayln` 的参数包进了加法里，把它踢出来。
```scheme
;; 初始状态 (光标在 (+ 10 20 ...) 内部):
(displayln (+ 10 20 "结束"))

;; 目标期望状态:
(displayln (+ 10 20) "结束")
```
* **操作步骤**：
  1. 光标停在 `(+ 10 20 "结束")` 括号内。
  2. 按一下 **`Alt + Shift + ←`**（Mac: **`⌥ + ⇧ + ←`**），右括号向左收缩，`"结束"` 被完美踢出加法！

---

### 练习 6：脱壳解包 Splice（`Alt + Shift + ↓` | Mac: `⌥ + ⇧ + ↓`）
**目标**：不需要 `let` 局部变量了，把内部的逻辑直接提取出来。
```scheme
;; 初始状态 (光标停在 (engine:log ...) 上):
(let ()
  (engine:log "运行中"))

;; 目标期望状态:
(engine:log "运行中")
```
* **操作步骤**：
  1. 按 **`Alt + ↑`**（Mac: **`⌥ + ↑`**）扩选到 `(let () ...)`。
  2. 按一下 **`Alt + Shift + ↓`**（Mac: **`⌥ + ⇧ + ↓`**），外层 `let` 瞬间被粉碎剥除，只保留核心代码！

---

### 练习 7：大步跨越与深度穿透（`Ctrl + 方向键` | Mac: `⌃ + 方向键`）
**目标**：不按几十次左右键，快速穿梭在各级参数之间。
```scheme
(define (make-card id name icon type)
  (hash "id" id "name" name "icon" icon))
```
* **操作步骤**：
  1. 光标在行首，按 **`Ctrl + →`**（Mac: **`⌃ + →`**）：光标直接跳到 `(make-card ...)` 后面。
  2. 按 **`Ctrl + ↓`**（Mac: **`⌃ + ↓`**）：直接钻入内部，停在 `id` 词首。
  3. 连续按 **`Ctrl + →`**（Mac: **`⌃ + →`**）：像跳石阶一样在 `id` $\rightarrow$ `name` $\rightarrow$ `icon` 之间大步跳跃。
  4. 按 **`Ctrl + ↑`**（Mac: **`⌃ + ↑`**）：瞬间跳出到函数外层。

---

### 练习 8：参数位置对调 Transpose（`Ctrl + Alt + →` | Mac: `⌃ + ⌥ + →`）
**目标**：将 `(equal? target current)` 快速修正为 `(equal? current target)`。
```scheme
;; 初始状态 (光标停在 target 与 current 之间):
(equal? target current)

;; 目标期望状态:
(equal? current target)
```
* **操作步骤**：
  1. 光标停在两个词中间。
  2. 按一下 **`Ctrl + Alt + →`**（Mac: **`⌃ + ⌥ + →`**），两项瞬间对调！

---

### 练习 9：一分为二 Split（`Ctrl + Alt + ↓` | Mac: `⌃ + ⌥ + ↓`）
**目标**：把一个大背包列表从中间拆成两个列表。
```scheme
;; 初始状态 (光标停在 "浆果" 与 "石头" 之间的空格处):
(list "苹果" "浆果" | "石头" "木头")

;; 目标期望状态:
(list "苹果" "浆果") ("石头" "木头")
```
* **操作步骤**：
  1. 光标定位在分割位置。
  2. 按一下 **`Ctrl + Alt + ↓`**（Mac: **`⌃ + ⌥ + ↓`**），列表干净利落切开成两半。

---

### 练习 10：整块安全删除 Kill（`Ctrl + Delete` / `Ctrl + Backspace` | Mac: `⌃ + Delete` / `⌃ + ⌫`）
**目标**：删掉无用的调试参数 `(debug-trace pid)`，绝不破坏括号对齐。
```scheme
;; 初始状态 (光标停在 (debug-trace pid) 前面):
(do-move-card pid src dst (debug-trace pid) 'tail)

;; 目标期望状态:
(do-move-card pid src dst 'tail)
```
* **操作步骤**：
  1. 光标停在 `(debug-trace pid)` 的左括号处。
  2. 按一下 **`Ctrl + Delete`**（Mac: **`⌃ + Delete`**），整组括号连同内部内容一口气消除，右侧自动闭合！

---

## 三、 总结：肌肉记忆口诀

> **向上选，向外扩（`Alt / ⌥ + ↑`）**  
> **拇指一按就发射（`Alt / ⌥ + Enter / Return`）**  
> **函数调用括号裹（`Alt / ⌥ + Shift / ⇧ + 9`）**  
> **方块绑定不写错（`Alt / ⌥ + [`）**  
> **缺了参数向右吸（`Alt / ⌥ + Shift / ⇧ + →`）**  
> **多了参数向左吐（`Alt / ⌥ + Shift / ⇧ + ←`）**  
> **拆除包装向下剥（`Alt / ⌥ + Shift / ⇧ + ↓`）**  
> **跨越穿透加 Ctrl / ⌃，手不离键写 Scheme！**
