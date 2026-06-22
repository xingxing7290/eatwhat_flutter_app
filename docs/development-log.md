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

## 2026-06-22 真机综合功能测试与修复

### 测试环境

- 设备：Samsung SM G973F，设备 ID `RF8M708L06Z`。
- 服务入口：`http://113.44.50.108:3002/api`。
- 测试账号：`phone_test_170142`。

### 发现并修复的问题

- 购物清单手动补充失败：客户端提交中文分类 `其他`，服务端枚举要求 `other`。
  - 修复：提交 `other`，页面展示时将 `vegetable/meat_egg/staple/seasoning/other` 映射为中文分类。
- 多个页面刷新触发 Flutter 调试错误：`setState() callback argument returned a Future`。
  - 修复：将所有异步 `future = load()` 的 `setState` 回调改为同步代码块。
- 周计划生成草稿显示为空：服务端返回 `preview` 和嵌套 `meals.breakfast/lunch/dinner`，客户端只读取平铺字段。
  - 修复：周计划展示优先读取 `preview`，并支持 `meals` 嵌套结构。
- 日历应用周计划后仍显示未安排：日历卡片同样只读取平铺餐次字段。
  - 修复：日历复用周计划餐次解析函数，支持 `schedule.meals.*`。
- 回忆保存失败：客户端将显示名传给 `participants`，服务端需要用户 ObjectId。
  - 修复：新增 `AppState.userId`，回忆保存时传用户 id；缺失 id 时传空数组。
- 回忆保存按钮靠近系统底部区域，真机自动化容易误触照片选择。
  - 修复：保存按钮固定到底部操作区，并增加底部触摸安全间距。

### 真机验证结果

- 登录成功，首页、菜谱、日历、回忆、设置页均可打开。
- 购物清单：手动新增、显示分类、勾选/清空已购流程通过。
- 想吃清单：新增、投票、标记已安排流程通过。
- 周计划：生成草稿后显示具体菜名，应用到日历成功。
- 日历：6 月 22 日显示 `番茄鸡蛋盖饭 / 牛肉盖饭 / 排骨饭`。
- 饭后回忆：保存 `dinner_memory4` 成功，回忆列表显示该记录。
- 纪念日菜单：模板创建成功，生成 `生日小餐桌`。
- 菜谱详情：默认菜品详情、封面、做过一次、编辑、图片纠错、食材入口均可渲染。
- 设置页：退出登录入口、功能入口、默认菜品状态 `407/407` 正常显示。

### 构建验证

- `dart format lib test` 通过。
- `flutter analyze` 通过。
- `flutter test` 通过，2 个测试全部通过。
- `flutter run -d RF8M708L06Z --debug --no-resident` 多次通过，已安装到真机。
- `flutter build apk --release` 未通过，原因是本机无法解析/下载 Flutter release engine 依赖：
  - `storage.flutter-io.cn`
  - `storage.googleapis.com`
  - `dl.google.com`
  - `repo.maven.apache.org`
  该失败为当前网络/DNS 依赖问题，不是代码编译错误；debug APK 已完成真机验证。
