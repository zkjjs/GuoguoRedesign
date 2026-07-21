# Guoguo 毛玻璃悬浮底栏设计

## 目标

为 `com.example.dongmangongheguo` 制作越狱注入式 `.deb`，保留原 Flutter App 的数据、登录、播放和页面逻辑，同时移除现有 FLEX 调试浮层，并将底部导航改造成 Apple 风格的悬浮毛玻璃胶囊。

## 已确认视觉

- 保留四个入口：发现、频道、任务、我的。
- 使用深色 iOS 系统色：黑色与石墨灰为主体，系统蓝为唯一功能强调色。
- 底栏为悬浮圆角胶囊，位于 Home Indicator 上方。
- 材质使用 `UIBlurEffectStyleSystemUltraThinMaterialDark`；使用低透明度描边和柔和阴影，避免彩色光晕。
- 图标使用 SF Symbols；选中项为系统蓝，未选中项为次级灰。
- 动漫封面保留自身色彩，不对内容图像强制染色。

## 技术边界

原 App 是 Flutter Release AOT，主程序和 `App.framework/App` 均已砸壳，但没有 Dart 源码。因此本版本不重写内容页；它通过运行时注入覆盖原底栏视觉，并把点击命中传给原 Flutter 底栏，从而保留功能。

## 交互

- 覆盖层本身不拦截触摸，点击仍由原 Flutter 底栏处理。
- 四个图标的水平分区与原底栏一致。
- 通过监听触摸结束位置更新原生覆盖层的选中态。
- 进入视频播放等非主页页面时隐藏覆盖层；回到包含底栏的主页时恢复。
- 支持横竖屏和安全区变化，布局在 `viewDidLayoutSubviews` 后重新计算。

## 兼容与恢复

- 目标最低系统为 iOS 15，覆盖用户设备 iOS 16.0.2。
- 同时提供 rootful 与 rootless package scheme。
- 仅在目标 Bundle ID 中加载。
- 卸载 `.deb` 后原 App 恢复原样，不修改用户数据。

## 验收标准

1. App 启动时不出现 FLEX 调试菜单。
2. 首页底部显示四入口悬浮毛玻璃胶囊。
3. 四个入口均可点击并切换原页面。
4. 选中态与当前页面一致。
5. Home Indicator、横竖屏和安全区布局正确。
6. 视频播放等二级页面不被底栏遮挡。

