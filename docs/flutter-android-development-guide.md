# 情侣夫妻饮食平台 Flutter Android App 开发文档

适用项目：xingxing7290/eatwhat
线上地址：http://113.44.50.108:3002
API 前缀：http://113.44.50.108:3002/api
当前分支：codex/complete-couple-food-system

本文档用于把现有 Vue + Express + MongoDB Web 系统完整梳理为 Flutter Android App 的开发说明，覆盖产品定位、现有项目结构、Flutter 架构、页面开发、后端 API 对接、数据模型、上传、测试和发布。

## 1. 项目定位

这是一个面向情侣、夫妻或同住小家的双人饮食记录平台。核心不是单纯的菜谱 CRUD，而是围绕两个人每天吃什么、想吃什么、吃完之后留下什么记忆展开。

核心业务：

- 小家共享：用户通过邀请码加入同一个 household，小家内共享菜品、排餐、想吃、回忆、购物清单和纪念日。
- 菜品库：支持默认北方常见餐品、用户自建菜品、图片、食材、步骤、标签、收藏、评分。
- 日历排餐：按日期和早餐、午餐、晚餐安排菜品。
- 周计划：规则生成一周菜单草稿，应用后写入日历。
- 购物清单：按排餐聚合食材，也支持手动补充和勾选已购。
- 饭后回忆：记录照片、评分、心情、备注、实际耗时和下次改进。
- 想吃清单：两人添加愿望、投票、标记计划或完成。
- 纪念日菜单：为生日、纪念日、节日等创建主题菜单。
- 图片治理：默认菜品导入、恢复图片、图片不对纠错。

Flutter Android 第一版目标：完整复用现有后端，不重写业务规则；移动端重点做好首页、日历、菜品、回忆、图片上传和双人互动体验；保证 Web 与 App 数据互通。

## 2. 当前系统结构

### 2.1 前端 Web

技术栈：Vue 3、Vue Router、Pinia、Element Plus、Axios、Vite、Nginx。

关键文件：

| 路径 | 说明 |
|---|---|
| client/src/router/index.js | Web 路由定义和登录守卫 |
| client/src/services/api.js | Axios API 封装，Flutter API 可参考此文件 |
| client/src/App.vue | 全局导航、登录状态、主题、退出登录 |
| client/src/views/LoginPage.vue | 登录页 |
| client/src/views/AccountApply.vue | 申请账号页 |
| client/src/views/DashboardPage.vue | 小家仪表盘 |
| client/src/views/CalendarPage.vue | 日历排餐 |
| client/src/views/MealPage.vue | 菜品列表 |
| client/src/views/MealDetail.vue | 菜品详情 |
| client/src/views/MealEditor.vue | 菜品编辑 |
| client/src/views/MemoryTimeline.vue | 饭后回忆 |
| client/src/views/PhotoAlbumPage.vue | 饭桌相册 |
| client/src/views/WishlistPage.vue | 想吃清单 |
| client/src/views/AnniversaryPage.vue | 纪念日菜单 |
| client/src/views/ShoppingListPage.vue | 购物清单 |
| client/src/views/WeeklyPlanPage.vue | 周计划 |
| client/src/views/UserSettings.vue | 设置页 |

### 2.2 后端

技术栈：Node.js、Express、Mongoose、MongoDB 7、JWT、Multer、Docker Compose。

关键文件：

| 路径 | 说明 |
|---|---|
| server/app.js | Express 应用、路由挂载、错误处理、上传静态目录 |
| server/routes/*.js | 路由定义 |
| server/controllers/*.js | 业务控制器 |
| server/models/*.js | MongoDB 数据模型 |
| server/middleware/auth.js | JWT 鉴权中间件 |
| server/middleware/upload.js | 图片上传配置，限制格式和大小 |
| server/utils/household.js | 创建小家、保证用户 household、初始化默认菜品 |
| server/utils/defaultMeals.js | 默认菜品图片、导入、恢复、兜底 SVG 生成 |
| server/data/defaultMeals.js | 默认菜品源数据，当前总数 407 |
| server/data/mealWebImages.json | 默认菜品图片映射 |
| server/uploads/ | 用户上传、默认菜品图片和生成图片 |

### 2.3 线上部署

| 服务 | 宿主机端口 | 容器端口 | 说明 |
|---|---:|---:|---|
| 公共入口 Nginx | 3002 | 80 | 外部访问入口 |
| 前端 Nginx | 127.0.0.1:8089 | 80 | 内部前端静态服务 |
| 后端 Express | 127.0.0.1:3003 | 3000 | 内部 API 服务 |
| MongoDB | 127.0.0.1:27018 | 27017 | 内部数据库 |

公共入口：

- Web：http://113.44.50.108:3002
- API：http://113.44.50.108:3002/api
- Uploads：http://113.44.50.108:3002/uploads/...
- Health：http://113.44.50.108:3002/health

Nginx 已设置 UTF-8：charset utf-8。

## 3. Flutter 项目建议

### 3.1 推荐依赖

建议使用 Flutter 3.x 稳定版、Dart 3.x。

推荐依赖：

    dio
    flutter_riverpod
    go_router
    flutter_secure_storage
    shared_preferences
    cached_network_image
    image_picker
    photo_view
    intl
    table_calendar
    collection
    json_annotation
    build_runner
    json_serializable
    mocktail
    integration_test

用途：

- Dio：统一 HTTP、Bearer Token、multipart 上传、错误拦截。
- Riverpod：状态管理和依赖注入。
- GoRouter：路由和登录态重定向。
- SecureStorage：保存 token。
- CachedNetworkImage：图片缓存和占位图。
- ImagePicker：头像、菜品、回忆照片选择。
- TableCalendar：日历页面。

### 3.2 Android 明文 HTTP 配置

当前服务是 HTTP。Android 9+ 默认限制明文流量。开发阶段必须配置。

推荐只允许当前服务器：

    AndroidManifest.xml application 节点添加：
    android:networkSecurityConfig="@xml/network_security_config"

    android/app/src/main/res/xml/network_security_config.xml：
    <network-security-config>
        <domain-config cleartextTrafficPermitted="true">
            <domain includeSubdomains="false">113.44.50.108</domain>
        </domain-config>
    </network-security-config>

后续生产建议配置 HTTPS，然后移除明文配置。

### 3.3 推荐目录

    lib/
      main.dart
      app.dart
      core/
        constants/app_config.dart
        network/api_client.dart
        network/api_exception.dart
        storage/token_storage.dart
        utils/date_formatters.dart
        utils/image_url.dart
        theme/app_theme.dart
        widgets/loading_view.dart
        widgets/error_view.dart
        widgets/empty_state.dart
      routes/app_router.dart
      features/
        auth/
        dashboard/
        meals/
        calendar/
        weekly_plan/
        shopping_list/
        memories/
        photo_album/
        wishlist/
        anniversaries/
        settings/

每个 feature 建议分为：data api、repository、models、providers、pages、widgets。

## 4. 移动端导航设计

Web 是顶部导航，App 不建议照搬。建议底部 5 个主 Tab：

1. 首页：仪表盘、今天吃什么、TA 想吃、快捷入口。
2. 日历：月视图排餐、快速安排早午晚餐。
3. 菜品：菜品列表、搜索、详情、新增编辑。
4. 回忆：饭后回忆时间线、相册入口。
5. 我的：设置、小家、默认菜品、图片纠错、退出登录。

二级入口：周计划、购物清单、想吃清单、纪念日菜单、饭桌相册。

## 5. 视觉规范

当前 Web 风格：日式原木风、现代温馨奶油风、轻复古、情侣小家语境。

推荐主题色：

| 名称 | 色值 | 用途 |
|---|---|---|
| cream | #FDFBF7 | 主背景 |
| oatmeal | #F5EBE6 | 次背景 |
| peach | #FFB4A2 | 主按钮、高亮 |
| caramel | #E09F67 | 辅助按钮 |
| coffee | #4A3E3D | 主文字 |
| softRed | #D85F65 | 强调、警示 |
| leaf | #7AA874 | 健康、完成 |

组件要求：背景奶油白或燕麦色；文字深咖色；卡片 16-24 圆角和柔和阴影；图片圆角并带占位图；按钮使用蜜桃粉或焦糖色；标签为胶囊样式；日历格子做便签或拍立得风格；菜品列表做精致网格或轻瀑布流。

## 6. 后端对接总规则

Base URL：

    apiBaseUrl = http://113.44.50.108:3002/api
    publicBaseUrl = http://113.44.50.108:3002

除注册、登录外，业务接口都需要：Authorization: Bearer token。

Token 当前 7 天过期。App 行为：登录成功后保存 token 到 flutter_secure_storage；Dio 拦截器自动注入 Authorization；遇到 401 清 token 并跳转登录；启动时调用 /auth/me 刷新用户和小家信息。

错误格式：

    { "error": "未认证" }

表单错误：

    { "errors": [{ "msg": "菜品名称不能为空", "path": "name" }] }

错误文案优先级：error -> errors[0].msg -> HTTP 默认文案 -> 网络错误文案。

图片 URL 可能是绝对地址、/uploads/... 或 /api/uploads/...。App 必须统一补全 publicBaseUrl。

上传规则：支持 jpeg、jpg、png、gif、webp；单文件最大 5MB；multipart/form-data；建议 App 上传前压缩到 1600px 以内，单图尽量小于 1MB。

## 7. 数据模型

### 7.1 User

字段：id/_id、username、role、displayName、avatarUrl、householdId、household。

### 7.2 Household

字段：id/_id、name、inviteCode、members、createdBy。

### 7.3 Meal

| 字段 | 类型 | 说明 |
|---|---|---|
| _id | string | 菜品 ID |
| householdId | string | 小家 ID |
| createdBy | string | 创建者 |
| name | string | 菜品名，必填，最多 100 |
| category | string | 分类 |
| subcategory | string | 子分类 |
| imageUrl | string | 封面图 |
| photos | string[] | 照片墙 |
| description | string | 简介，最多 1000 |
| tags | string[] | 标签 |
| ingredients | Ingredient[] | 食材 |
| steps | CookingStep[] | 做法步骤 |
| tips | string | 烹饪技巧 |
| servingSize | string | 份量 |
| prepTime | number | 准备时间 |
| cookTime | number | 烹饪时间 |
| difficulty | string | easy/medium/hard/空 |
| taste | string[] | 口味 |
| healthTags | string[] | 健康标签 |
| spiceLevel | number | 0-5 |
| source | string | 来源 |
| isDefault | bool | 是否默认菜品 |
| defaultKey | string | 默认菜品 key |
| favorite | bool | 收藏 |
| rating | number | 0-5 |

Ingredient：name、amount。CookingStep：description、imageUrl。

### 7.4 Schedule

按 householdId + date 唯一。字段：date、meals.breakfast、meals.lunch、meals.dinner。每个餐次项包含 meal 和 addedBy。

### 7.5 MealMemory

字段：date、mealType、title、note、mood、rating、actualCookTime、nextImprovement、photos、mealIds、participants、createdBy。

### 7.6 WishlistItem

字段：title、note、mealId、category、priority、status、votes、createdBy、createdByPartner、votedByMe、votedByPartner、partnerSignal。

### 7.7 ShoppingList

字段：weekStart、generatedFrom、items。Item 字段：name、amount、category、checked、manual、sourceMealIds、addedBy。

分类：vegetable 蔬菜、meat_egg 肉蛋、staple 主食、seasoning 调料、other 其他。

### 7.8 AnniversaryMenu

字段：title、date、description、theme、photos、meals.breakfast/lunch/dinner。

### 7.9 MealImageIssue

字段：mealId、issueType、note、status、createdBy、resolvedBy、resolvedAt。issueType 为 wrong_image、missing_image、low_quality、other。status 为 open、fixed、ignored。

## 8. API 明细

### 8.1 Auth

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| POST | /api/auth/register | 否 | 注册，带邀请码则加入小家，不带则创建小家 |
| POST | /api/auth/login | 否 | 登录，返回 token/user/household |
| GET | /api/auth/me | 是 | 当前用户和小家 |
| PUT | /api/auth/profile | 是 | 更新昵称 |
| POST | /api/auth/avatar | 是 | 上传头像，字段 avatar |

注册 body：username、password、displayName、inviteCode、householdName。

### 8.2 Household

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/household/me | 获取小家 |
| PUT | /api/household/me | 修改小家名，body name |
| POST | /api/household/invite/refresh | 刷新邀请码 |
| POST | /api/household/join | 加入小家，body inviteCode |

### 8.3 Meals

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/meals | 菜品列表，支持分页和筛选 |
| GET | /api/meals/categories | 分类和子分类统计 |
| GET | /api/meals/tags | 标签列表 |
| GET | /api/meals/stats | 菜品统计 |
| GET | /api/meals/:id | 菜品详情 |
| POST | /api/meals | 创建菜品，multipart |
| PUT | /api/meals/:id | 更新菜品，multipart |
| DELETE | /api/meals/:id | 删除菜品 |

列表参数：search、tag、category、subcategory、difficulty、favorite=true、page、limit。传 page 或 limit 时启用分页，limit 最大 200。App 应始终分页。

菜品创建/更新 multipart 字段：name、description、category、subcategory、tags、ingredients、steps、tips、servingSize、prepTime、cookTime、difficulty、taste、healthTags、spiceLevel、source、sourcePath、favorite、rating、image、photos、stepImages、stepImageIndexes、existingPhotos。

数组字段必须 JSON encode 成字符串。

### 8.4 Schedules

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/schedules?year=2026&month=6 | 查询月份排餐 |
| PUT | /api/schedules/:date/:mealType | 设置某日某餐 |

mealType：breakfast、lunch、dinner。body：mealIds 数组。清空传空数组。

### 8.5 Dashboard

GET /api/dashboard/summary。返回 today、weekStart、todaySchedule、todayHints、week、partnerWishlist、recentPhotos、defaultMeals、imageIssues、meals。

### 8.6 Weekly Plans

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/weekly-plans?weekStart=YYYY-MM-DD | 查询本周排餐汇总 |
| POST | /api/weekly-plans/generate | 生成周菜单草稿，不写日历 |
| POST | /api/weekly-plans/apply | 应用草稿到日历 |

### 8.7 Shopping List

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/shopping-list?weekStart=YYYY-MM-DD | 获取购物清单 |
| POST | /api/shopping-list/generate | 按排餐生成或刷新 |
| POST | /api/shopping-list/items | 新增手动项 |
| PATCH | /api/shopping-list/items/:id | 更新名称、数量、分类、勾选 |
| DELETE | /api/shopping-list/items/:id?weekStart=... | 删除项 |
| DELETE | /api/shopping-list/purchased?weekStart=... | 清空已购 |

### 8.8 Memories

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/memories | 列表，支持 date/month/mealId |
| POST | /api/memories | 创建，multipart，字段 photos |
| PUT | /api/memories/:id | 更新，multipart |
| DELETE | /api/memories/:id | 删除 |

创建/更新字段：date、mealType、title、note、mood、rating、actualCookTime、nextImprovement、mealIds、participants、existingPhotos、photos。

### 8.9 Photo Album

GET /api/photo-album?month=YYYY-MM。按月份聚合饭后回忆照片。

### 8.10 Wishlist

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/wishlist?status=open | 想吃列表 |
| POST | /api/wishlist | 创建 |
| POST | /api/wishlist/:id/vote | 投票或取消投票 |
| PATCH | /api/wishlist/:id/status | 更新状态 |
| DELETE | /api/wishlist/:id | 删除 |

priority：low、normal、high。status：open、planned、done。

### 8.11 Anniversaries

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/anniversaries | 列表 |
| POST | /api/anniversaries | 创建，multipart |
| PUT | /api/anniversaries/:id | 更新，multipart |
| DELETE | /api/anniversaries/:id | 删除 |

字段：title、date、description、theme、meals、photos。meals 是 JSON object，breakfast/lunch/dinner 对应菜品 ID 数组。

### 8.12 Anniversary Templates

GET /api/anniversary-templates。当前返回 5 个固定模板。

### 8.13 Default Meals

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/default-meals/status | 默认菜品导入状态 |
| POST | /api/default-meals/import-missing | 导入缺失默认菜品 |
| POST | /api/default-meals/restore-images | 恢复默认菜品图片 |

当前默认菜品总数：407。

### 8.14 Meal Image Issues

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | /api/meal-image-issues?status=open | 图片问题列表 |
| POST | /api/meal-image-issues | 创建图片问题 |
| PATCH | /api/meal-image-issues/:id | 更新状态和备注 |

## 9. 页面开发说明

### 9.1 登录页

功能：用户名密码登录、记住账号、跳转首页、申请账号入口。接口：POST /api/auth/login。成功后保存 token、user、household，跳转 dashboard。失败显示后端错误。App 不建议明文保存密码，可以只保存用户名。

### 9.2 申请账号页

接口：POST /api/auth/register。字段：昵称、小家名称、邀请码、用户名、密码、确认密码。无邀请码创建新小家，有邀请码加入已有小家。前端校验：用户名 3-20 字符、密码不少于 6 字符、两次密码一致。

### 9.3 首页仪表盘

接口：GET /api/dashboard/summary。展示今天三餐、今日搭配提醒、本周饭桌计划、TA 想吃、最近饭桌照片、默认菜品和图片状态、快捷入口。支持安排晚餐、进入周计划、进入购物清单、进入设置。

### 9.4 日历页

接口：GET /api/schedules、PUT /api/schedules/:date/:mealType、GET /api/wishlist?status=open。UI 使用月视图、今天高亮、每格三餐胶囊标签、空餐添加入口、TA 想吃提醒。点击餐次进入菜品选择；长按清空；从想吃项安排到今天晚餐。

### 9.5 菜品列表页

接口：GET /api/meals、GET /api/meals/categories、GET /api/meals/tags。必须分页。UI 包含搜索、分类、标签、难度、收藏筛选；卡片显示图片、名称、简介、耗时、难度、评分、标签、食材。

### 9.6 菜品详情页

接口：GET /api/meals/:id、GET /api/memories?mealId=:id、POST /api/meal-image-issues。展示封面、照片墙、简介、食材、步骤、步骤图、技巧、回忆。操作：做过一次、图片不对、编辑、删除、收藏评分。

### 9.7 菜品编辑页

接口：POST /api/meals、PUT /api/meals/:id。表单分区：基础信息、图片、食材、做法、偏好标签、其他信息。重点：数组字段 JSON encode；图片字段名和后端一致。

### 9.8 菜品选择页

输入 date 和 mealType。接口：GET /api/meals、PUT /api/schedules/:date/:mealType。支持搜索、多选、保存后返回日历。

### 9.9 周计划页

接口：GET /api/weekly-plans、POST /api/weekly-plans/generate、POST /api/weekly-plans/apply。generate 只生成草稿；apply 才写入日历。

### 9.10 购物清单页

接口：shopping-list 全组。UI 按蔬菜、肉蛋、主食、调料、其他分组；支持生成、手动新增、勾选、删除、清空已购。后端只文本合并数量，不做单位换算。

### 9.11 饭后回忆页

接口：memories 全组。UI 为时间线；卡片显示日期、餐次、照片、菜品、心情、评分、备注。新增页支持照片上传，字段名 photos。

### 9.12 饭桌相册页

接口：GET /api/photo-album?month=YYYY-MM。UI 为月份切换、照片网格、大图预览、日期/餐次/菜品/心情/备注。

### 9.13 想吃清单页

接口：wishlist 全组。UI 为 open/planned/done 分段；高优先级突出；TA 创建或投票显示 partnerSignal；支持投票和安排晚餐。

### 9.14 纪念日菜单页

接口：anniversaries 和 anniversary-templates。UI 为模板选择、日期、主题、早午晚菜品选择、照片和备注。

### 9.15 设置页

接口：auth/profile、auth/avatar、household、default-meals、meal-image-issues。功能：头像、昵称、主题色、小家名称、邀请码复制/刷新、成员、默认菜品管理、图片纠错、退出登录。

## 10. Flutter API Client 示例

Dio Client 需要做三件事：设置 baseUrl；请求前从 SecureStorage 读取 token 并注入 Authorization；响应 401 时清理 token 并让路由回登录页。

Multipart 创建菜品时，tags、ingredients、steps、taste、healthTags 必须 jsonEncode；封面字段 image；照片墙字段 photos；步骤图字段 stepImages；步骤图索引字段 stepImageIndexes。

## 11. 缓存和离线策略

第一版建议轻缓存，不做复杂离线写入。可缓存：当前用户、小家、主题、dashboard summary、菜品分类/标签、菜品列表第一页。不建议离线写入：图片上传、菜品编辑、日历排餐、购物清单勾选。原因是 Web 与 App 双端共享，离线冲突处理成本高。

## 12. 测试方案

### 12.1 后端联调测试

覆盖：注册 A 创建小家；注册 B 邀请码加入；A/B 登录并确认 householdId；默认菜品状态；菜品分页搜索详情；菜品创建编辑和图片上传；日历三餐设置；周计划 generate/apply；购物清单生成、手动新增、勾选、清空；PNG 回忆上传和相册；想吃投票和状态；纪念日模板和菜单；图片纠错；不同小家隔离。

### 12.2 Flutter 单元测试

测试 JSON model、图片 URL 归一化、错误解析、日期工具、表单校验、购物清单分组、周计划草稿转换。

### 12.3 Widget 测试

测试登录表单、申请账号校验、菜品卡片、日历餐次标签、购物清单勾选、回忆卡片、设置页退出登录。

### 12.4 Integration Test

真实链路：打开 App，申请账号，登录，查看首页，创建 B 加入小家，想吃投票，生成周计划，购物清单，上传 PNG 回忆，相册，图片纠错，退出登录。

### 12.5 性能目标

| 项目 | 目标 |
|---|---:|
| 冷启动到登录页 | < 2.5s |
| 登录到首页 | < 2s |
| 首页加载 | < 1.5s |
| 菜品首屏 | < 2s |
| 图片上传 1MB | < 5s |

优化要求：菜品列表分页，图片缓存，首页只用 summary，详情再加载大图。

## 13. Android 发布准备

需要 INTERNET 权限。若用系统 Photo Picker，可减少相册权限；如需传统权限，需要按 Android 版本处理 READ_MEDIA_IMAGES 或旧版存储权限。

包名建议：com.xingxing7290.eatwhat。应用名建议：安排吃啥 或 小家饭桌。

环境配置建议通过 dart-define 注入 API_BASE_URL：

    flutter run --dart-define=API_BASE_URL=http://113.44.50.108:3002/api
    flutter build apk --release --dart-define=API_BASE_URL=http://113.44.50.108:3002/api

## 14. 开发里程碑

1. 基础框架：主题、路由、Dio、TokenStorage、登录、注册。
2. 只读数据：首页、日历、菜品列表、菜品详情。
3. 写入能力：菜品编辑、图片上传、排餐。
4. 情侣功能：想吃、回忆、相册、做过一次。
5. 增强功能：周计划、购物清单、纪念日、默认菜品、图片纠错。
6. 测试发布：单测、Widget、Integration、真机、Release APK。

## 15. 验收清单

功能验收：

- 注册创建小家。
- 邀请码加入小家。
- 登录和退出。
- 首页 summary。
- 日历排餐。
- 菜品分页、搜索、详情。
- 菜品新增、编辑、删除和图片上传。
- 饭后回忆和 PNG 上传。
- 相册查看。
- 想吃清单投票和状态。
- 周计划生成和应用。
- 购物清单操作。
- 纪念日菜单。
- 默认菜品导入和恢复图片。
- 图片纠错。
- 设置页头像、昵称、小家、邀请码、主题。

技术验收：

- Token 使用 secure storage。
- 401 自动退出。
- Android 明文 HTTP 配置正确。
- 图片 URL 兼容相对和绝对地址。
- Multipart 字段名和后端一致。
- 列表有 loading/error/empty/success 状态。
- 大列表分页，不一次加载 407 张图。
- 保存和上传按钮防重复点击。
- 删除操作二次确认。
- 真机测试通过。

## 16. 当前线上测试基线

最近一次完整浏览器测试报告：docs/test-reports/2026-06-22-full-browser-test.md。

结论：完整浏览器测试 14 项通过；控制台错误 0；请求失败 0；后端 5xx 0；页面最慢约 1.376 秒；PNG 上传通过；测试数据已清理。

## 17. 后续建议

1. 给线上服务配置 HTTPS，移除 Android 明文 HTTP 配置。
2. 后端补充 OpenAPI/Swagger，降低 Flutter 对接成本。
3. 增加菜品轻量列表接口，只返回卡片字段，减少移动端流量。
4. 增加缩略图能力，列表加载缩略图，详情加载原图。
5. 增加 refresh token 或更适合移动端的长期登录机制。
6. 生产环境限制或关闭 debug 路由。
7. 默认菜品图片继续人工校准，App 保留“图片不对”反馈入口。
