# 清理Godot编辑器缓存和设置
Write-Host "正在清理Godot编辑器缓存和设置..."

# 删除.godot缓存文件夹
if (Test-Path .godot) {
    Write-Host "删除.godot缓存文件夹..."
    Remove-Item -Recurse -Force .godot
}

# 删除.import缓存文件夹（如果存在）
if (Test-Path .import) {
    Write-Host "删除.import缓存文件夹..."
    Remove-Item -Recurse -Force .import
}

# 删除编辑器设置文件
Write-Host "删除编辑器设置文件..."
Remove-Item -Path "editor_settings-*.tres" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "editor_layout_*.tres" -Force -ErrorAction SilentlyContinue

Write-Host "清理完成！"
Write-Host ""
Write-Host "请重新启动Godot编辑器并打开项目。"
Write-Host "如果脚本仍然显示为空，请尝试以下步骤："
Write-Host "1. 在Godot编辑器中，转到编辑器 -> 编辑器设置"
Write-Host "2. 搜索'text_editor'"
Write-Host "3. 检查'Text Editor -> Files -> Encoding'设置是否为UTF-8"
Write-Host "4. 检查'Text Editor -> Files -> Auto Reload'是否启用"
Write-Host ""
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")