# Flutter Android 客户端开发日志

## 2026-06-22

### 初始化

- 在 `E:\git\eatwhat_flutter_app` 创建独立 Flutter 项目，未在 `E:\git\ai_customize_resume` 中写入或修改业务代码。
- 使用当前本机 Flutter 环境创建项目：`Flutter 3.27.5-ohos-1.0.1 / Dart 3.6.2`。
- 没有执行 `flutter upgrade`、`flutter channel`、`flutter config` 或 Android SDK 许可证变更。
- 从服务器 `/srv/eatwhat/docs/flutter-android-development-guide.md` 同步开发文档到 `docs/flutter-android-development-guide.md`。
- 初始化独立 Git 仓库并提交：`chore: 初始化 Flutter Android 项目和开发文档`。

### 依赖

- `http`：对接现有 Express API。
- `shared_preferences`：保存 token 与记住密码设置。
- `image_picker`：选择菜品封面、饭后回忆照片并通过 multipart 上传。

### 功能开发

- 替换 Flutter 默认计数器页面为“安排吃啥”业务应用。
- 登录后进入小家首页；底部导航提供首页、日历、菜谱、回忆、设置。
- 接入服务器现有接口：认证、小家、菜品、日历、回忆、周计划、购物清单、想吃清单、饭桌相册、纪念日菜单、默认菜品、图片纠错。
- Android 增加 `INTERNET` 权限、相册读取权限和 `113.44.50.108` 明文 HTTP 访问配置。
- README 改为客户端运行说明与 Git 开发流程。

### 验证结果

- `dart format lib test`
  - 结果：通过。
- `flutter analyze`
  - 结果：通过，`No issues found!`。
- `flutter test`
  - 结果：通过，登录壳组件测试通过。
- `flutter build apk --debug`
  - 结果：本机 Flutter wrapper 阶段因 `services.gradle.org` 下载 Gradle 发行包超时失败；未超过 10 分钟，失败点已确认是网络下载，不是 Dart/Android 编译错误。
- `gradle assembleDebug`
  - 结果：通过，成功生成 `build\app\outputs\flutter-apk\app-debug.apk`。
- `flutter devices`
  - 结果：当前只检测到 Windows、Chrome、Edge，没有 Android 真机或模拟器，因此未做真机启动验证。

### 构建产物

- Debug APK：`build\app\outputs\flutter-apk\app-debug.apk`
- 文件大小：约 73.8 MB

### 说明

- 由于本机已有系统 Gradle 8.1，使用 `gradle assembleDebug` 绕过 Gradle Wrapper 下载超时完成 Android 构建。
- 没有修改 Flutter SDK、Flutter channel、Android SDK 许可证或全局 Gradle 配置。

## 2026-06-22 登录后红屏修复

### 问题

- 登录成功进入“小家首页”后出现 Flutter 红屏。
- 错误信息：`dependOnInheritedWidgetOfExactType<AppScope>() ... was called before _DashboardPageState.initState() completed`。

### 原因

- 多个页面在 `initState()` 中通过 `context.app` 读取 `InheritedNotifier`，这会建立依赖关系。
- Flutter 不允许在 `initState()` 阶段调用会依赖 `InheritedWidget` 的读取方法。

### 修复

- 在 `AppScope` 增加非监听读取方法 `read()`。
- 新增 `context.appRead`，用于初始化阶段只读取 `AppState`，不建立依赖。
- 将首页、日历、菜谱、回忆、周计划、购物清单、想吃清单、相册、纪念日、设置等页面初始化请求改为 `context.appRead`。

### 验证

- `dart format lib test` 通过。
- `flutter analyze` 通过，`No issues found!`。
- `flutter test` 通过。
- `gradle assembleDebug` 通过，已重新生成 debug APK。

## 2026-06-22 AppScope 读取方式全量排查

### 排查范围

- 扫描 `lib/main.dart` 中全部 `context.app` 调用点。
- 检查所有 `initState()`、初始化加载函数、异步回调和按钮回调。

### 调整

- 将命令式操作统一改为 `context.appRead`：
  - 登录页保存账号密码。
  - 日历排餐保存。
  - 菜谱图片纠错、菜谱保存。
  - 饭后回忆保存。
  - 周计划生成与应用。
  - 购物清单生成、补充、勾选、删除。
  - 想吃清单新增、投票、状态变更、删除。
  - 纪念日模板创建。
  - 设置页修改资料、小家、默认菜品、图片问题处理、退出登录。
- 仅保留 `build()` 中用于显示状态的 `context.app` 读取：
  - 应用鉴权壳。
  - 顶部小家名称。
  - 首页昵称。
  - 设置页小家信息。

### 回归测试

- 新增组件测试：`appRead can be used during initState without subscribing`。
- 该测试在 `initState()` 中读取 `context.appRead`，防止同类红屏问题回归。

### 验证

- `dart format lib test` 通过。
- `flutter analyze` 通过，`No issues found!`。
- `flutter test` 通过，2 个测试全部通过。
- `gradle assembleDebug` 通过，已重新生成 debug APK。

## 2026-06-22 手机真机测试与网络诊断

### 真机环境

- 设备：Samsung SM G973F
- 设备 ID：`RF8M708L06Z`
- 系统：Android 12 / API 31

### 构建和安装

- 首次执行 `flutter run -d RF8M708L06Z --debug --no-resident` 时，Gradle Wrapper 卡在 `services.gradle.org` 下载。
- 将项目内 Gradle Wrapper 下载源切换为腾讯云 Gradle 镜像：`https://mirrors.cloud.tencent.com/gradle/gradle-8.3-bin.zip`。
- 再次执行 `flutter run -d RF8M708L06Z --debug --no-resident` 成功构建、安装并启动。

### 手机端页面验证

- 首次启动显示登录页正常。
- 没有复现登录后 `AppScope` 红屏。
- ADB 抓屏和 UI 树已保存到 `test-results/phone/`。

### 服务端连通性诊断

- 本机 TCP 探测：
  - `22`：OPEN，但 SSH 卡在 banner 阶段。
  - `3000`：OPEN。
  - `3001`：OPEN，但 HTTP 请求超时。
  - `3002`：OPEN，`/health` 返回 `healthy`。
  - `8088`：CLOSED。
  - `8089`：CLOSED。
  - `27018`：CLOSED。
- 手机侧：
  - `3002/health` 可以返回 `healthy`。
  - `3002/api/auth/me` 超时。
- 结论：
  - 目前不是 `3002` 安全组未放行导致的问题。
  - `3002` Nginx 健康入口可用，但 `/api/*` 后端链路超时，疑似 backend 容器、Mongo 连接或服务器负载异常。
  - `22` TCP 可连接但 SSH banner 超时，疑似服务器 sshd 或系统负载异常。

### 客户端修复

- 为所有普通 HTTP 请求增加 15 秒超时。
- 为 multipart 上传增加 15 秒超时。
- 超时后提示：`服务器响应超时，请检查网络或稍后重试`。
- 避免后端卡住时手机端一直等待。
