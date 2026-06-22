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
