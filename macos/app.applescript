-- quietmd.app —— 让 Finder 双击 .md 时调用 mdview 渲染并在浏览器打开。
-- 用 AppleScript 而不是普通 shell 脚本，是因为只有它能接收 Finder 的
-- 「打开文档」事件（on open），从而拿到被双击的文件路径。

on open theFiles
	repeat with f in theFiles
		set p to POSIX path of (f as alias)
		try
			-- 后台跑：渲染完 mdview 自己会调浏览器打开，app 不必等它
			do shell script "$HOME/.local/bin/quietmd " & quoted form of p & " > /dev/null 2>&1 &"
		on error errMsg
			display alert "quietmd 打开失败" message (p & return & return & errMsg) as warning
		end try
	end repeat
end open

-- 直接双击 app 图标本身（而不是拖文件进来）时，让用户挑一个文件
on run
	try
		set f to choose file with prompt "选择要阅读的 Markdown 文件"
		open {f}
	on error number -128
		-- 用户按了取消，安静退出
	end try
end run
