# CFBlog Mobile App

基于 Expo + React Native Web 的跨平台移动客户端，面向现有 `cfblog` 后端，覆盖：

- iOS
- Android
- Web

## 目标能力

- 登录、注册、会话保持
- 文章、页面、动态的创建/编辑/发布
- 评论与动态评论管理
- 媒体上传与元数据维护
- 分类、标签、友链、友链分类管理
- 用户与站点设置管理
- 适合日常更新的移动端快捷入口

## 启动

```bash
npm install
npm run web
```

或：

```bash
npm run android
npm run ios
```

## 自动打包

仓库已包含 GitHub Actions 自动打包工作流：

- [build-app.yml](\.github\workflows\build-app.yml)
- [release.yml](\.github\workflows\release.yml)

触发方式：

- 推送 `v*` tag 时自动打包
- 在 GitHub Actions 里手动触发，选择 `android / ios / web / all`

打包策略：

- `web`：执行 `npm run build:web`，并上传 `dist` 为构建产物
- `android / ios`：通过 EAS Build 云端打包

打包前你需要准备：

- GitHub Secret: `EXPO_TOKEN`
- Expo / EAS 项目已初始化
- 建议在 `app.json` 中补全 `android.package` 和 `ios.bundleIdentifier`

EAS 构建配置见：

- [eas.json](C:\Users\Administrator\Desktop\新建文件夹\cfblog-app\eas.json)

## 连接后端

应用首次打开时填写你的 CFBlog 站点地址，例如：

```text
https://your-domain.com
```

客户端会自动请求：

```text
https://your-domain.com/wp-json/
https://your-domain.com/wp-json/wp/v2/*
```

## 说明

- 默认面向后台更新操作，而不是博客前台阅读器。
- 如果当前账号不是管理员，设置、用户等模块会受后端权限控制。
