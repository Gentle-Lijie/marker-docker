# Portainer 部署指南 / Portainer Deployment Guide

本指南介绍如何使用 Portainer 部署 Marker PDF 转换服务。

This guide explains how to deploy the Marker PDF converter service using Portainer.

## 前提条件 / Prerequisites

1. 已安装 Docker
2. 已安装并运行 Portainer
3. 可以访问 Portainer Web UI

## 部署方式 / Deployment Methods

### 方式一：使用 Docker Compose 堆栈 (推荐)

#### 1. 登录 Portainer

访问 Portainer Web UI（通常是 `http://your-server:9000`）

#### 2. 创建新堆栈

1. 在左侧菜单选择 **Stacks**（堆栈）
2. 点击 **Add stack**（添加堆栈）
3. 输入堆栈名称：`marker-pdf`

#### 3. 配置堆栈

在 **Web editor** 中粘贴以下内容：

```yaml
services:
  marker:
    image: ghcr.io/gentle-lijie/marker-docker:latest
    container_name: marker-server
    ports:
      - "8000:8000"
    volumes:
      - marker-uploads:/app/uploads
      - marker-outputs:/app/outputs
    environment:
      - TORCH_DEVICE=cpu
      # 如需使用 LLM 功能，取消下面的注释并填入您的 API Key
      # - GOOGLE_API_KEY=your_api_key_here
      # - ANTHROPIC_API_KEY=your_api_key_here
    restart: unless-stopped
    # GPU 支持（需要 nvidia-docker）
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  marker-uploads:
  marker-outputs:
```

#### 4. 部署

1. 点击 **Deploy the stack**（部署堆栈）
2. 等待容器启动（首次运行会下载镜像，需要几分钟）
3. 在 Stacks 页面查看状态

#### 5. 验证部署

访问 `http://your-server:8000` 查看 API 主页

访问 `http://your-server:8000/docs` 查看 API 文档

---

### 方式二：使用单个容器

#### 1. 在 Portainer 中创建容器

1. 在左侧菜单选择 **Containers**（容器）
2. 点击 **Add container**（添加容器）

#### 2. 基本配置

- **Name**: `marker-server`
- **Image**: `ghcr.io/gentle-lijie/marker-docker:latest`

#### 3. 网络端口配置

在 **Network ports configuration** 部分：

| Host | Container |
|------|-----------|
| 8000 | 8000      |

点击 **publish a new network port** 添加端口映射

#### 4. 高级容器设置

**Volumes（卷）:**

点击 **Volumes** 标签，添加：

| Container path | Bind/Volume | Volume/Bind path |
|---------------|-------------|------------------|
| `/app/uploads` | volume | `marker-uploads` |
| `/app/outputs` | volume | `marker-outputs` |

**Environment variables（环境变量）:**

点击 **Env** 标签，添加：

| Name | Value |
|------|-------|
| `TORCH_DEVICE` | `cpu` |
| `GOOGLE_API_KEY` | `your_key_here`（可选） |
| `ANTHROPIC_API_KEY` | `your_key_here`（可选） |

**Restart policy（重启策略）:**

选择 **Unless stopped**

#### 5. 部署容器

点击 **Deploy the container** 按钮

---

## GPU 支持配置 / GPU Support

如果您的服务器有 NVIDIA GPU 并且已安装 nvidia-docker：

### 在 Stack 中启用 GPU

取消 docker-compose.yml 中 GPU 部分的注释：

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

并将环境变量改为：
```yaml
- TORCH_DEVICE=cuda
```

### 在单个容器中启用 GPU

1. 在 **Runtime & Resources** 标签下
2. 找到 **GPU** 设置
3. 选择要使用的 GPU

并添加环境变量：
- `TORCH_DEVICE`: `cuda`

---

## 环境变量说明 / Environment Variables

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `TORCH_DEVICE` | 计算设备 | `cpu` | `cpu`, `cuda`, `mps` |
| `GOOGLE_API_KEY` | Gemini API 密钥（可选） | - | `AIza...` |
| `ANTHROPIC_API_KEY` | Claude API 密钥（可选） | - | `sk-ant-...` |
| `OPENAI_API_KEY` | OpenAI API 密钥（可选） | - | `sk-...` |
| `AZURE_ENDPOINT` | Azure OpenAI 端点（可选） | - | `https://...` |
| `AZURE_API_KEY` | Azure API 密钥（可选） | - | `...` |

详细配置请参考 [`.env.example`](.env.example) 文件。

---

## 使用 API / Using the API

部署成功后，您可以通过以下方式使用 API：

### 通过浏览器访问

- **API 主页**: `http://your-server:8000`
- **交互式文档**: `http://your-server:8000/docs`

### 使用 curl 上传 PDF

```bash
curl -X POST "http://your-server:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=markdown"
```

### 使用 Python 调用 API

```python
import requests

with open("document.pdf", "rb") as f:
    response = requests.post(
        "http://your-server:8000/marker/upload",
        files={"file": ("document.pdf", f, "application/pdf")},
        data={"output_format": "markdown"}
    )
    
    result = response.json()
    if result["success"]:
        print(result["output"])
```

---

## 监控和日志 / Monitoring and Logs

### 查看容器日志

1. 在 Portainer 中进入 **Containers** 页面
2. 点击 `marker-server` 容器
3. 选择 **Logs** 标签
4. 可以看到实时日志输出

### 查看容器统计

1. 在容器详情页面
2. 选择 **Stats** 标签
3. 可以查看 CPU、内存、网络使用情况

### 健康检查

容器配置了自动健康检查，每 30 秒检查一次。

在容器列表中可以看到健康状态图标。

---

## 更新镜像 / Updating the Image

### 方式一：通过 Portainer UI

1. 在 **Containers** 页面找到 `marker-server`
2. 点击 **Recreate**（重建）
3. 勾选 **Pull latest image**（拉取最新镜像）
4. 点击 **Recreate**

### 方式二：通过 Stack 更新

1. 进入 **Stacks** 页面
2. 点击 `marker-pdf` 堆栈
3. 点击 **Editor**（编辑器）
4. 点击 **Update the stack**（更新堆栈）
5. 勾选 **Re-pull image and redeploy**

---

## 故障排除 / Troubleshooting

### 容器无法启动

1. 检查日志中的错误信息
2. 确认端口 8000 未被占用
3. 检查卷挂载权限

### 无法访问 API

1. 确认容器状态为 **running**
2. 检查端口映射是否正确（8000:8000）
3. 检查防火墙设置
4. 尝试访问健康检查端点：`http://your-server:8000/`

### 内存不足

1. 在容器设置中增加内存限制
2. 或使用 `page_range` 参数分批转换大文件

### 权限问题

如果遇到卷权限问题：

1. 在 Portainer 终端中执行：
```bash
chown -R 1000:1000 /app/uploads /app/outputs
```

---

## 高级配置 / Advanced Configuration

### 使用自定义端口

如果 8000 端口被占用，可以映射到其他端口：

在端口配置中将 Host 改为其他值，例如 `8080:8000`

访问时使用：`http://your-server:8080`

### 使用外部卷

如果需要将数据存储在特定位置：

1. 创建主机目录：
```bash
mkdir -p /data/marker/uploads /data/marker/outputs
```

2. 在 Portainer 卷配置中使用 **Bind** 类型：
   - Container: `/app/uploads`
   - Bind: `/data/marker/uploads`

### 使用私有镜像仓库

如果您构建了自己的镜像：

1. 在 Portainer 中配置 **Registries**
2. 添加您的镜像仓库凭证
3. 在部署时使用您的镜像地址

---

## 备份和恢复 / Backup and Restore

### 备份卷数据

在 Portainer 终端中执行：

```bash
docker run --rm -v marker-uploads:/source -v /backup:/dest busybox tar czf /dest/uploads.tar.gz -C /source .
docker run --rm -v marker-outputs:/source -v /backup:/dest busybox tar czf /dest/outputs.tar.gz -C /source .
```

### 恢复卷数据

```bash
docker run --rm -v marker-uploads:/dest -v /backup:/source busybox tar xzf /source/uploads.tar.gz -C /dest
docker run --rm -v marker-outputs:/dest -v /backup:/source busybox tar xzf /source/outputs.tar.gz -C /dest
```

---

## 参考文档 / References

- [README.Docker.md](README.Docker.md) - Docker 部署详细指南
- [DOCKER_SETUP.md](DOCKER_SETUP.md) - 技术架构文档
- [examples/README_DOCKER_EXAMPLES.md](examples/README_DOCKER_EXAMPLES.md) - API 使用示例
- [Portainer 官方文档](https://docs.portainer.io/)

---

## 需要帮助？ / Need Help?

如有问题，请：

1. 查看容器日志排查错误
2. 访问 API 文档页面测试功能
3. 参考上述文档
4. 在 GitHub 提交 Issue

---

**祝您使用愉快！ / Happy deploying! 🚀**
