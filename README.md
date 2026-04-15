# iFont-sw

本地 iOS 9~17 & 18~26 字体转换工具，支持 TTF / OTF / TTC 批量转换。

基于[iFont-huamidev](https://github.com/huami1314/iFont)开发

UI好看，所以试着写一下。
## 功能

- 支持 TTF / OTF / TTC 输入，输出 iOS 兼容的 TTC / TTF 格式
- 批量转换，多文件自动打包下载
- 三种字重映射模式可选
- 极简黑白 UI，终端风格日志
- 完全本地处理，无需网络上传

## 环境要求

- iOS 16.0+
- macOS (用于 Xcode 编译)

## 使用方法

1. 在 Xcode 中打开 `iFont-sw.xcodeproj`
2. 连接 iOS 设备或启动模拟器
3. 运行项目，上传自定义字体文件
4. 选择字重映射模式
5. 点击 START，等待转换完成
6. 下载生成的 TTC / TTF 文件，导入 iOS 设备

## 字重映射模式

| 模式 | 说明 |
|------|------|
| 全局统配 | 所有字重统一使用常规体 |
| 粗细分离 | 区分常规与中黑 |
| 三阶层次 | 细 / 常 / 粗组合 |

## 项目结构

```
iFont-sw/
├── ContentView.swift          # 主视图
├── FontConverter.swift        # 字体转换引擎
├── FontModels.swift           # 数据模型
├── FontCache.swift            # 字体缓存
├── FontTemplate.swift         # 模板加载
├── Components/                # UI 组件
│   ├── CustomSlider.swift
│   ├── SvgIcons.swift
│   ├── FontPreviewComponents.swift
│   ├── FontPreviewUIKit.swift
│   └── ShareSheet.swift
└── Extensions/                # 扩展
    ├── UTType+Font.swift
    └── CGPath+SVG.swift
```

## 技术栈

- SwiftUI
- CoreText / CoreGraphics
- UniformTypeIdentifiers

## 联系

- GitHub: [@hhse](https://github.com/hhse)
- Telegram: [@TheBallnow](https://t.me/TheBallnow)

## License

© 2026 iFont-sw [@hhse](https://github.com/hhse)
