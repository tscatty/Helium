# Helium 3.2.6 滚动文字（弹幕）扩展

本工程基于 leminlimez/Helium 3.2.6（GPL-3.0，原仓库已归档）修改，新增一个「滚动文字」小部件，
文字在该显示位的框内像抖音弹幕一样循环横向滚动，滚动窗口（可见范围）由显示位自身的位置与尺寸决定。

## 一、改动清单

新增文件：

| 文件 | 作用 |
| --- | --- |
| `src/hud/HeliumMarqueeLabel.h` | 滚动标签对外接口 |
| `src/hud/HeliumMarqueeLabel.mm` | UILabel 子类，按共享时钟在自身 bounds 内绘制位移文字 |

修改文件：

| 文件 | 改动 |
| --- | --- |
| `src/hud/HUDRootViewController.mm` | label 与动态取色遮罩改为 HeliumMarqueeLabel；按显示位里的滚动配置驱动滚动；含滚动文字时强制固定宽度；锁屏时停滚动 |
| `src/widgets/WidgetManager.mm` | 新增 widgetID = 10（滚动文字）的文本分支，并在标识符注释表登记 |
| `src/controllers/WidgetManager.swift` | `WidgetModule` 新增 `scrollText = 10`，补充名称与示例 |
| `src/views/widget/WidgetPreferencesView.swift` | 滚动文字设置页：内容、速度、间隔、方向 |
| `src/views/widget/WidgetPreviewsView.swift` | 预览分支 |
| `en.lproj/Localizable.strings` | 8 条英文文案 |
| `zh-Hans.lproj/Localizable.strings` | 8 条中文文案 |

完整补丁见同目录 `scrolltext.patch`。

## 二、配置项（存在 widgetProperties 的 widgetIDs 里）

| key | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `widgetID` | Int | 10 | 滚动文字部件标识 |
| `text` | String | 空 | 参与滚动的内容，可与时间/电量等部件共存；为空时只当作「开启滚动」的开关 |
| `speed` | Double | 30 | 滚动速度，单位 pt/s，界面 5–150 |
| `gap` | Double | 24 | 两轮文字之间的空白间隔，单位 pt，界面 0–120 |
| `direction` | Int | 0 | 0 = 从右到左，1 = 从左到右 |

## 三、使用步骤

1. Helium 设置 → 选择一个显示位（左上 / 中间 / 右上）进入编辑。
2. 「部件」里添加「滚动文字」，再按需要往里加时间、电量等其它部件，它们会一起滚动。
3. 进入滚动文字的部件设置，填内容、调速度、调间隔、选方向。
4. 回到显示位设置，用宽（scale）/ 高（scaleY）/ 锚点 / 偏移确定滚动窗口的位置和大小。
5. 保存，HUD 会自动重载。

## 四、范围控制原理

- 可见范围就是该显示位自己的 frame：`scale`（宽）× `scaleY`（高），超出部分被标签 bounds 裁掉，所以调宽高和左右锚点/偏移就是调「能看到多远」。
- 含滚动文字时 `autoResizes` 会被忽略并强制使用固定尺寸，否则标签会撑到整段文字宽度，等于没有滚动。
- 文字宽度小于窗口宽度时不滚动，退化为普通静态文本。

## 五、构建

- 需要 macOS + Theos（`xcrun clang`、`ldid`）。Windows 本机没有 iOS SDK 与 ld64，无法直接编译。
- 构建：`./ipabuild.sh`，产物为 `build/Helium.tipa`，分享到巨魔商店安装。
- 也可用仓库自带的 `.github/workflows/release.yml` 在 macOS runner 上出包。

> 状态：本轮只完成代码修改与静态自检（括号平衡、枚举覆盖、本地化 key 一致），**未经过编译验证**。

## 六、已知限制

- 滚动每帧重绘，30fps；锁屏时自动停滚，但屏幕常亮期间有额外耗电。
- 动态取色模式下正文标签与遮罩标签共用一个时钟，相位一致；两者各自起一个定时器。
- 文字内容更新（例如同显示位里的时间每秒刷新）不会重置滚动相位，视觉上不会跳。
