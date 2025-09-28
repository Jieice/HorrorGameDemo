@echo off
echo 正在清理Godot编辑器缓存...

REM 删除.godot缓存文件夹
if exist ".godot" (
    echo 删除.godot缓存文件夹...
    rmdir /s /q .godot
)

REM 删除.import缓存文件夹
if exist ".import" (
    echo 删除.import缓存文件夹...
    rmdir /s /q .import
)

REM 删除编辑器设置文件
echo 删除编辑器设置文件...
del /f /q editor_settings-*.tres >nul 2>&1
del /f /q editor_layout_*.tres >nul 2>&1

echo 清理完成！
echo.
echo 请重新启动Godot编辑器并打开项目。
echo 如果脚本仍然显示为空，请尝试以下步骤：
echo 1. 在Godot编辑器中，转到编辑器 -^> 编辑器设置
echo 2. 搜索"text_editor"
echo 3. 检查"Text Editor -^> Files -^> Encoding"设置是否为UTF-8
echo 4. 检查"Text Editor -^> Files -^> Auto Reload"是否启用
echo.
echo 按任意键退出...
pause > nul