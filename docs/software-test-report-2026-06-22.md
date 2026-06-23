# 情侣饭桌 Flutter App 软件测试报告

## 1. 文档信息

| 项目 | 内容 |
| --- | --- |
| 测试对象 | 情侣饭桌 Flutter App |
| 测试日期 | 2026-06-22 至 2026-06-23 |
| 当前代码基线 | `c239112 feat: 支持饭后回忆拍照添加照片` |
| 测试类型 | 静态检查、单元测试、接口冒烟测试、Android 真机手工验证、截图核验 |
| 测试结论 | 通过。本轮未发现阻塞登录、核心页面访问、接口主链路、PNG 上传、回忆拍照入口和默认菜品导入的缺陷。 |

## 2. 测试环境

| 类型 | 环境 |
| --- | --- |
| 开发机 | Windows 10.0.19045.6466 |
| Flutter | 3.27.5-ohos-1.0.1 |
| Dart | 3.6.2 |
| 真机 | Samsung SM-G973F |
| 真机系统 | Android 12, API 31 |
| 真机分辨率 | Physical `1440x3040`, Override `1080x2280` |
| 服务端 | `http://113.44.50.108:3002/api` |
| 健康检查 | `http://113.44.50.108:3002/health` 返回 healthy |
| QA 小家 | `qa_api_20260622220113` 所属小家，邀请码 `E4280A` |

说明：QA 账号只用于本轮测试。接口测试脚本不再内置密码，需通过命令参数或环境变量传入。

## 3. 测试范围

本轮覆盖以下模块：

- 登录态和用户信息：登录、`/auth/me`、邀请码注册并加入同一小家。
- 首页与仪表盘：小家首页、今日饭桌、本周计划摘要、默认菜品状态。
- 日历排餐：月视图、周计划应用后的排餐读取。
- 菜谱：默认菜品读取、菜谱列表展示、图片加载代表样例。
- 回忆：JSON 创建、PNG 图片上传、图库选择入口、相机拍摄入口、按月查询、相册聚合。
- 想吃清单：创建、投票、状态流转。
- 本周计划：查询、规则生成草稿、应用到日历。
- 购物清单：从周计划生成、手动补充、勾选。
- 纪念日菜单：模板接口与移动端页面入口。
- 设置：小家邀请码、退出登录入口、功能入口、默认菜品管理状态。
- 图片纠错：创建问题、查询待处理问题。

## 4. 自动化检查结果

| 检查项 | 命令 | 结果 |
| --- | --- | --- |
| 格式检查 | `dart format --output=none --set-exit-if-changed lib test` | 通过，0 个文件变更 |
| 静态分析 | `flutter analyze` | 通过，No issues found |
| 单元测试 | `flutter test` | 通过，2/2 |
| 真机启动安装 | `flutter run -d RF8M708L06Z --debug --no-resident` | 通过，已安装并启动到 Android 真机 |
| 回忆照片入口 | 真机打开“记录饭后回忆”并滚动到照片区域 | 通过，显示“从图库选择”和“拍照添加”两个入口 |
| 相机调用 | 点击“拍照添加”后检查前台 Activity | 通过，调起 `com.sec.android.app.camera/.Camera` |

单元测试用例：

- `shows login shell when no saved token exists`
- `appRead can be used during initState without subscribing`

## 5. 接口冒烟测试结果

测试脚本：`tools/api_smoke_test.ps1`

最终结果文件：`test-results/api-smoke-result.json`

最终统计：

| 总数 | 通过 | 失败 |
| --- | --- | --- |
| 24 | 24 | 0 |

运行方式示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\api_smoke_test.ps1 `
  -Username <QA_USERNAME> `
  -Password <QA_PASSWORD> `
  -PhotoPath test-results\full-test-2026-06-22\11-home-valid.png
```

接口明细：

| 用例 | 覆盖内容 | 结果 |
| --- | --- | --- |
| AUTH_LOGIN | 登录并返回 token、用户、小家 | 通过 |
| AUTH_ME | 获取当前用户和小家邀请码 | 通过 |
| AUTH_REGISTER_WITH_INVITE | 使用邀请码注册并加入同一小家 | 通过 |
| DEFAULT_STATUS | 默认菜品状态，总数 407、已导入 407、缺失 0 | 通过 |
| DEFAULT_IMPORT_MISSING | 导入缺失默认菜品，不重复创建 | 通过 |
| MEALS_LIST | 获取菜谱列表并取得菜品 ID | 通过 |
| DASHBOARD_SUMMARY | 首页汇总、今日排餐、默认菜品、图片问题统计 | 通过 |
| WEEKLY_QUERY | 查询本周饭桌计划 | 通过 |
| WEEKLY_GENERATE | 生成本周菜单草稿 | 通过 |
| WEEKLY_APPLY | 应用周计划到日历 | 通过 |
| SCHEDULES_QUERY | 使用 `year` + `month` 查询排餐 | 通过 |
| SHOPPING_GENERATE | 从周计划生成购物清单 | 通过 |
| SHOPPING_ADD_MANUAL | 手动补充购物项 | 通过 |
| SHOPPING_CHECK_ITEM | 勾选购物项 | 通过 |
| WISHLIST_CREATE | 创建想吃项 | 通过 |
| WISHLIST_VOTE | 投票想吃项 | 通过 |
| WISHLIST_STATUS | 更新想吃项状态为 planned | 通过 |
| MEMORY_CREATE_JSON | 创建饭后回忆 JSON 数据 | 通过 |
| MEMORIES_QUERY | 按月份查询饭后回忆 | 通过 |
| MEMORY_CREATE_PNG | multipart 上传 PNG 到饭后回忆 | 通过 |
| PHOTO_ALBUM_QUERY | 饭桌相册按月聚合照片 | 通过 |
| ANNIVERSARY_TEMPLATES | 获取纪念日菜单模板 | 通过 |
| IMAGE_ISSUE_CREATE | 提交菜品图片纠错 | 通过 |
| IMAGE_ISSUES_QUERY | 查询待处理图片纠错 | 通过 |

## 6. Android 真机验证结果

截图证据目录：`test-results/full-test-2026-06-22/`，回忆照片入口截图为 `test-results/memory-photo-actions.png`。

有效截图：

| 截图 | 页面 | 核验结果 |
| --- | --- | --- |
| `11-home-valid.png` | 小家首页 | 页面可打开，主题样式正常，首页数据展示正常 |
| `12-calendar-valid.png` | 双人日历 | 日历便签卡片正常展示，无崩溃、无明显文字溢出 |
| `13-meals-final.png` | 菜谱列表 | 默认菜品可加载，菜品卡片、标签、图片区域正常 |
| `14-memories-valid.png` | 回忆时间线 | 页面可打开，中文显示正常，旧测试标题 `dinner_memory4` 非乱码 |
| `15-settings-valid.png` | 设置页首屏 | 小家信息、退出登录、功能入口可见 |
| `21-weekly-plan-valid.png` | 本周计划 | 已生成的周计划可展示 |
| `22-shopping-list-valid.png` | 购物清单 | 购物项可展示，按钮布局正常 |
| `23-wishlist-valid.png` | 想吃清单 | 空态和添加入口正常 |
| `24-photo-album-valid.png` | 饭桌相册 | 空态正常 |
| `25-anniversary-valid.png` | 纪念日菜单 | 已创建菜单可展示，模板入口正常 |
| `26-settings-recheck.png` | 设置页复查 | 默认菜品状态为总数 407、已导入 407、缺失 0 |
| `test-results/memory-photo-actions.png` | 记录饭后回忆 | 照片区域显示“从图库选择”和“拍照添加”，按钮布局正常 |

无效截图处理：

- 早期 `02-calendar-final.png` 等截图曾被第三方应用抢占焦点，已排除，不作为测试证据。
- 早期菜谱和日历截图抓取过快，出现加载态，已等待接口返回后重新抓取有效截图。

## 7. 本轮发现并处理的问题

| 问题 | 类型 | 处理结果 |
| --- | --- | --- |
| API 冒烟脚本曾使用旧的 `/schedules?month=YYYY-MM` 查询方式 | 测试脚本问题 | 已改为当前接口要求的 `year` + `month` 参数 |
| API 冒烟脚本曾内置 QA 密码 | 测试脚本安全性 | 已改为参数或环境变量传入 |
| PowerShell 5 对 UTF-8 无 BOM 脚本中的中文提示解析不稳定 | 测试脚本兼容性 | 脚本运行时错误提示改为 ASCII |
| PowerShell 直接重定向 `adb exec-out screencap -p` 会损坏 PNG | 测试环境问题 | 改用 `adb shell screencap` + `adb pull` |
| 第三方应用抢占真机焦点导致截图不是本 App | 测试环境问题 | 强制停止第三方应用并重新启动本 App |
| 设置页默认菜品状态曾在旧截图中显示 0 | 截图时机问题 | 重新进入设置页等待 6 秒后复查，状态为 407/407/0 |
| 饭后回忆照片原来只有图库选择入口 | 功能补强 | 已新增“拍照添加”，补充 Android `CAMERA` 权限，并在真机确认能调起系统相机 |

## 8. 结论

本轮测试通过。当前 Flutter App 在 Android 真机上可以完成登录态页面访问、首页、日历、菜谱、回忆、设置和五个二级功能入口的核心浏览流程；服务端 24 个关键接口冒烟测试全部通过，包含 PNG 图片上传验证。饭后回忆照片已同时支持图库选择和相机拍摄入口，拍照入口已在真机调起系统相机。

默认菜品管理在 QA 小家和当前真机账号中均显示总数 407、已导入 407、缺失 0。PNG 上传后的图片能进入饭桌相册聚合结果。

## 9. 残余风险与建议

- 本轮没有逐张人工核验 407 个默认菜品图片与菜名的语义匹配，只验证了默认菜品数量、代表图片显示和上传链路。菜品图片准确性仍建议作为单独的数据审核任务持续治理。
- 本轮主要验证 Android 真机，未覆盖 iOS 真机、低端 Android 机型和弱网场景。
- 本轮未做正式性能压测。手工操作中未观察到明显卡顿，远程数据页需要等待接口返回，加载体验仍受网络和服务器响应影响。
- API 冒烟测试会在 QA 小家生成测试数据，包括成员、想吃项、回忆、购物项和图片纠错记录；需要保持 QA 小家与真实用户数据隔离。
