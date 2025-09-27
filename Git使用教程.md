# Git使用教程

## 初始设置

如果是第一次使用Git，需要设置用户名和邮箱：

```
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

## 基本操作流程

### 1. 初始化仓库（只需执行一次）

```
git init
```

### 2. 添加远程仓库（只需执行一次）

```
git remote add origin https://github.com/Jieice/HorrorGameDemo
```

### 3. 日常更新流程

每次修改代码后，使用以下命令保存更改：

```
git add .                                  # 添加所有修改的文件
git commit -m "更新说明：简单描述你做了什么修改"  # 提交更改并添加说明
git push                                   # 推送到远程仓库
```

## 常用命令说明

### 查看状态

```
git status  # 查看当前仓库状态，显示哪些文件被修改
```

### 查看远程仓库

```
git remote -v  # 查看远程仓库配置
```

### 拉取远程更新

如果在其他设备上修改了代码，需要在当前设备上获取这些更改：

```
git pull  # 拉取远程仓库的更新并合并
```

### 查看提交历史

```
git log  # 查看提交历史
```

### 创建和切换分支

```
git branch 分支名称     # 创建新分支
git checkout 分支名称   # 切换到指定分支
```

或者一步完成：

```
git checkout -b 分支名称  # 创建并切换到新分支
```

## 常见问题解决

### 如果推送失败

可能需要先拉取远程更新：

```
git pull --rebase  # 拉取远程更新并重新应用本地修改
git push           # 再次尝试推送
```

### 如果发生冲突

编辑冲突文件，解决冲突后：

```
git add .                     # 添加解决冲突后的文件
git commit -m "解决合并冲突"    # 提交解决冲突的更改
git push                      # 推送到远程仓库
```

## 提交规范建议

为了保持提交历史的清晰，建议在commit信息中使用以下前缀：

- `修复：` - 修复bug
- `功能：` - 添加新功能
- `优化：` - 代码优化，不影响功能
- `文档：` - 更新文档
- `测试：` - 添加测试用例
- `重构：` - 代码重构

例如：
```
git commit -m "修复：对话框打字机效果闪烁问题"
git commit -m "功能：添加游戏暂停菜单"
```

## 备份建议

定期创建项目备份：

```
# 创建带时间戳的备份目录
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "D:\Games\GodotDemo\horror_demo_backup_$timestamp"
New-Item -ItemType Directory -Path $backupDir
Copy-Item -Path "D:\Games\GodotDemo\horror_demo\*" -Destination $backupDir -Recurse
```