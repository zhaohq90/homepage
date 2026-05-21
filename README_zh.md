<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="images/banner_light@2x.png">
    <img src="images/banner_dark@2x.png" width="65%">
  </picture>
</p>

<p align="center">
  一个现代化、<em>完全静态、快速</em>、安全<em>全代理</em>、高度可定制的应用仪表板，支持超过 100 种服务集成和多语言翻译。可通过 YAML 文件轻松配置，或通过 docker 标签自动发现。
</p>

<p align="center">
  <img src="images/1.png?v=2" />
</p>

<p align="center">
  <a href="https://github.com/gethomepage/homepage/actions/workflows/docker-publish.yml"><img alt="GitHub Workflow Status (with event)" src="https://img.shields.io/github/actions/workflow/status/gethomepage/homepage/docker-publish.yml"></a>
  &nbsp;
  <a href="https://codecov.io/gh/gethomepage/homepage"><img src="https://codecov.io/gh/gethomepage/homepage/graph/badge.svg?token=***"></a>
  &nbsp;
  <a href="https://crowdin.com/project/gethomepage" target="_blank"><img src="https://badges.crowdin.net/gethomepage/localized.svg"></a>
  &nbsp;
  <a href="https://discord.gg/k4ruYNrudu"><img alt="Discord" src="https://img.shields.io/discord/1019316731635834932"></a>
  &nbsp;
  <a href="https://gethomepage.dev/" title="Docs"><img title="Docs" src="https://github.com/gethomepage/homepage/actions/workflows/docs-publish.yml/badge.svg"/></a>
  &nbsp;
  <a href="https://paypal.me/phelpsben" title="Donate"><img alt="GitHub Sponsors" src="https://img.shields.io/github/sponsors/benphelps"></a>
</p>

# 功能特性

Homepage 具有快速搜索、书签、天气支持、丰富的集成和小部件、优雅现代的设计以及注重性能等特性，是您开启每一天的理想选择，也是全天候的得力助手。

- **快速** - 网站在构建时静态生成，实现即时加载。
- **安全** - 所有对后端服务的 API 请求都经过代理，保护您的 API 密钥安全。由社区持续进行安全审查。
- **面向所有人** - 支持 AMD64、ARM64 架构的镜像。
- **完整国际化** - 支持超过 40 种语言。
- **服务和网络书签** - 在主页添加自定义链接。
- **Docker 集成** - 容器状态和统计信息。通过标签自动发现服务。
- **服务集成** - 超过 100 种服务集成，包括流行的 starr 应用和自托管应用。
- **信息和实用小部件** - 天气、时间、日期、搜索等功能。
- **更多功能...**

## Docker 集成

Homepage 内置 Docker 支持，可以根据标签自动发现并添加服务到主页。更多信息请参阅 [Docker 服务发现](https://gethomepage.dev/configs/docker/#automatic-service-discovery) 页面。

## 服务小部件

Homepage 还支持数百种第三方服务，包括所有流行的 \*arr 应用和大多数流行的自托管应用。例如：Radarr、Sonarr、Lidarr、Bazarr、Ombi、Tautulli、Plex、Jellyfin、Emby、Transmission、qBittorrent、Deluge、Jackett、NZBGet、SABnzbd 等。除了服务集成外，Homepage 还有多个信息提供器，从各种外部第三方 API 获取信息。更多信息请参阅 [服务](https://gethomepage.dev/widgets/) 页面。

## 信息小部件

Homepage 内置支持多种信息提供器，包括天气、时间、日期、搜索、Glances 等。系统和状态信息显示在页面顶部。更多信息请参阅 [信息提供器](https://gethomepage.dev/widgets/) 页面。

## 自定义

Homepage 高度可定制，支持自定义主题、自定义 CSS 和 JS、自定义布局、格式化、本地化等功能。更多信息请参阅 [设置](https://gethomepage.dev/configs/settings/) 页面。

# 快速开始

有关配置选项、示例等内容，请查看 [Homepage 文档](http://gethomepage.dev)。

## 安全须知 🔒

请注意，当使用小部件等功能时，Homepage 可以访问个人信息（例如来自您的智能家居系统），而 Homepage 目前不（也不计划）包含任何身份验证层。如果 Homepage 可以从任何不受信任的网络访问，它**必须**位于一个强制执行身份验证、TLS 并严格验证 Host 头的反向代理（和/或 VPN）之后。Homepage 内置的主机检查只是一个尽力而为的防护措施，在公开暴露时不应被视为安全保障。

## 使用 Docker

使用 docker compose：

```yaml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    environment:
      HOMEPAGE_ALLOWED_HOSTS: gethomepage.dev # 必填，可能需要端口。参见 gethomepage.dev/installation/#homepage_allowed_hosts
      PUID: 1000 # 可选，您的用户 ID
      PGID: 1000 # 可选，您的组 ID
    ports:
      - 3000:3000
    volumes:
      - /path/to/config:/app/config # 确保您的本地配置目录存在
      - /var/run/docker.sock:/var/run/docker.sock:ro # 可选，用于 docker 集成
    restart: unless-stopped
```

或使用 docker run：

```bash
docker run --name homepage \
  -e HOMEPAGE_ALLOWED_HOSTS=gethomepage.dev \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 3000:3000 \
  -v /path/to/config:/app/config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  ghcr.io/gethomepage/homepage:latest
```

## 从源码构建

首先，克隆仓库：

```bash
git clone https://github.com/gethomepage/homepage.git
```

然后安装依赖并构建生产版本：

```bash
pnpm install
pnpm build
```

如果是首次启动，请将 `src/skeleton` 目录复制到 `config/` 以生成初始示例配置文件。

最后，以生产模式运行服务器：

```bash
pnpm start
```

# 配置

更多信息请参阅 [Homepage 文档网站](https://gethomepage.dev/)。所有关于配置 Homepage 的信息都在那里。在寻求帮助之前，请仔细阅读所有内容，因为大多数问题都可以在那里找到答案，或者只是简单的 YAML 配置问题。

# 开发

安装 NPM 包，本项目使用 [pnpm](https://pnpm.io/)（您也应该使用！）：

```bash
pnpm install
```

启动开发服务器：

```bash
pnpm dev
```

打开 [http://localhost:3000](http://localhost:3000) 开始。

这是一个 [Next.js](https://nextjs.org/) 应用，更多信息请参阅其文档。

# 文档

Homepage 文档可在 [https://gethomepage.dev/](https://gethomepage.dev/) 查看。

Homepage 使用 Zensical 编写文档。要在本地运行文档，首先安装依赖：

```bash
uv sync
```

然后运行开发服务器：

```bash
uv run zensical serve # 或使用 build 构建静态站点
```

# 支持与建议

如果您有任何问题、建议或一般性问题，请在 [Discussions](https://github.com/gethomepage/homepage/discussions) 页面发起讨论。

## 故障排除

除了文档外，[故障排除指南](https://gethomepage.dev/troubleshooting/) 可以帮助解决许多基本的配置或网络问题。如果您遇到问题，这是一个很好的起点。

## 贡献与贡献者

欢迎贡献！更多信息请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 文件。

感谢超过 200 位贡献者帮助这个项目发展至今！

特别感谢 [@shamoon](https://github.com/shamoon)，他从一开始就是这个社区的中流砥柱。