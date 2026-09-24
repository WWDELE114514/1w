# Windows 运行包

本运行包由 GitHub Actions 构建，适用于 Windows x64，无需安装 Go 或 Docker。

1. 将整个运行包解压到一个目录，双击 `start.cmd`，服务在后台运行。
2. 打开 <http://127.0.0.1:7863/panel/>。
3. 用文本编辑器打开 `config.json`，复制 `api_key` 的值登录面板。
4. 在面板中添加自己的 CodeBuddy 账号并完成授权，然后创建客户端 API 密钥。
5. 客户端 OpenAI Base URL 填 `http://127.0.0.1:7863/v1`，模型可选 `auto`。

双击 `stop.cmd` 停止服务。首次启动会从样例生成配置和随机管理员密钥；后续启动保留配置。
默认只允许本机访问，监听地址在 `config.json` 的 `listen` 中设置，修改后重启生效。
日志在 `logs/`，账号授权在 `auths/`，用量及状态在 `data/`。重启电脑后需重新运行 `start.cmd`。

升级时先停止服务，再替换可执行文件和启动脚本，保留 `config.json`、`auths/` 和 `data/`。
`BUILD_COMMIT.txt` 记录构建的源码提交，`SHA256SUMS.txt` 记录可执行文件校验值。

## 从源码仓库获取运行包

进入 GitHub 仓库的 **Actions → Build Windows Package → Run workflow**。
构建成功后，在该次运行底部 **Artifacts** 下载 `workbuddy2api-windows-amd64`。
产物保留 30 天，到期可重新运行工作流。
