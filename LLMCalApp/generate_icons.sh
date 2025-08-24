#!/bin/bash

# 创建基本的 SVG 图标
cat > base_icon.svg << EOL
<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#34C759;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#30B7F7;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="1024" height="1024" rx="224" ry="224" fill="url(#grad)"/>
  <g transform="translate(512,512) scale(0.6)" fill="white">
    <path d="M-300,-200 L300,-200 L300,200 L-300,200 Z" stroke="white" stroke-width="40" fill="none"/>
    <path d="M-200,-200 L-200,200" stroke="white" stroke-width="20"/>
    <path d="M0,-200 L0,200" stroke="white" stroke-width="20"/>
    <path d="M200,-200 L200,200" stroke="white" stroke-width="20"/>
    <path d="M-300,-100 L300,-100" stroke="white" stroke-width="20"/>
    <path d="M-300,0 L300,0" stroke="white" stroke-width="20"/>
    <path d="M-300,100 L300,100" stroke="white" stroke-width="20"/>
  </g>
</svg>
EOL

# 安装必要的工具
if ! command -v rsvg-convert &> /dev/null; then
    brew install librsvg
fi

# 创建输出目录
ICON_DIR="Sources/LLMCalApp/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

# 生成不同尺寸的图标
for size in 16 32 64 128 256 512 1024; do
    rsvg-convert -w $size -h $size base_icon.svg > "$ICON_DIR/icon_$size.png"
done

# 清理临时文件
rm base_icon.svg
