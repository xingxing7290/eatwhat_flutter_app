# 安排吃啥 Flutter Android App

这是“情侣夫妻双人饮食平台”的 Flutter Android 客户端，独立于现有 Web 项目和 `ai_customize_resume` 仓库。

## 项目边界

- 本项目目录：`E:\git\eatwhat_flutter_app`
- 后端地址：`http://113.44.50.108:3002/api`
- 资源地址：`http://113.44.50.108:3002`
- 不修改 Flutter SDK、channel、Android SDK 许可证或任何全局配置。
- 项目代码适配当前本机 Flutter：`Flutter 3.27.5-ohos-1.0.1 / Dart 3.6.2`

## 已实现功能

- 登录、记住密码、申请账号、邀请码加入小家。
- 小家首页：周计划、购物清单、想吃清单、相册、纪念日菜单入口。
- 双人日历：月视图、按早午晚安排菜品。
- 菜谱：列表、搜索、详情、新增、编辑、封面图上传、图片纠错。
- 饭后回忆：时间线、新增回忆、多图上传、关联菜品、做过一次。
- 本周饭桌计划：生成草稿、应用到日历。
- 购物清单：从周计划生成、手动添加、勾选、删除、清空已购。
- 想吃清单：新增、投票、标记已安排、删除。
- 饭桌相册：按月份读取回忆图片。
- 纪念日菜单：基于模板创建。
- 设置：修改昵称、小家名称、退出登录、默认菜品导入与图片恢复、图片问题管理。

## 运行

```bash
flutter pub get
flutter run -d android
```

如果使用连接的 Android 设备或模拟器，请确保设备能访问 `http://113.44.50.108:3002`。

## 验证

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

如果本机 Gradle Wrapper 下载 `services.gradle.org` 超时，但系统已经安装 Gradle，可以在 `android` 目录执行：

```bash
gradle assembleDebug
```

本次验证生成的 APK 路径：

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## 文档

- `docs/flutter-android-development-guide.md`：从服务器项目同步下来的 Flutter Android 开发文档。
- `docs/development-log.md`：本客户端开发日志和验证记录。

## Git 流程

- 本目录是独立 Git 仓库。
- 后续开发建议使用 `codex/<任务名>` 分支。
- 每次修改前检查 `git status`，修改后运行分析、测试、构建，再提交中文 commit。
