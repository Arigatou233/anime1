# 番剧档案馆（GitHub Pages + Supabase）

## 当前版本
- `index.html`：响应式前端，包含搜索、季度/年份筛选、作品卡片、详情时间点、投稿表单和规则说明。
- 页面可直接在浏览器预览；未配置后端时为**本机演示模式**，示例数据会保存在当前浏览器的 localStorage，不会同步到其他设备。
- `schema.sql`：Supabase 数据表与基础 RLS 策略。

## 发布到 GitHub Pages
1. 在 GitHub 新建一个公开仓库，例如 `anime-cut-archive`。
2. 上传 `index.html`、`schema.sql`、`README.md`。
3. 仓库 Settings → Pages → Build and deployment 选择 `Deploy from a branch`，分支选择 `main`、目录选择 `/ (root)`，保存。
4. 等待部署完成，GitHub Pages 会显示网站地址。

## 接入真实云端功能
1. 创建 Supabase 项目。
2. 在 SQL Editor 执行 `schema.sql`。
3. 在 Authentication 设置允许的登录方式，并注册你的管理员账号。
4. 将 `index.html` 中 `SUPABASE_URL` 与 `SUPABASE_ANON_KEY` 填为项目 URL 和公开 anon/publishable key（不要放 service_role key）。
5. 目前这个包的前端仍是演示模式；要实现真实注册登录、跨浏览器同步、评论审核和安全的管理员合并，需要继续接入 Supabase JS 客户端与受保护的 Edge Function。请勿把 service_role key 放在 GitHub Pages 前端。
6. 设置好管理员身份后，再实现审核后台；审核接口必须在服务端验证管理员身份，批准后才写入 `anime` / `cut_records`。

## 数据模型
- `anime`：作品元数据
- `cut_records`：每集删减时间点
- `proposals`：待审核的新建/修改/删除申请
- `comments`：留言与审核状态
- `profiles`：账号资料与管理员标记

## 安全说明
当前 RLS 是安全起点，不等于完整成品。不要开放正式表的客户端写权限；不要仅依赖隐藏按钮判断管理员权限。管理员审核与合并需要服务端验证。
