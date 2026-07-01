#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_NAME="PostureGuardiOS"
XCODEPROJ_DIR="${PROJECT_NAME}.xcodeproj"

echo "=== 1. 清理旧工程文件 ==="
rm -rf "${XCODEPROJ_DIR}"

echo "=== 2. 运行 xcodegen 生成 Xcode 工程 ==="
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
else
    echo "错误: xcodegen 未安装! 请先安装 (brew install xcodegen)。"
    exit 1
fi

echo "=== 3. 运行 xcodebuild 进行编译核验 ==="
if [ -d "${XCODEPROJ_DIR}" ]; then
    # 如果存在完整的 Xcode.app，则显式指定 DEVELOPER_DIR 避免命令行工具实例的指向错误
    if [ -d "/Applications/Xcode.app" ]; then
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    fi

    # 编译目标为 iOS 模拟器以进行静态编译测试，免去真机证书签名要求
    xcodebuild -project "${XCODEPROJ_DIR}" \
               -scheme "${PROJECT_NAME}" \
               -configuration Debug \
               -sdk iphonesimulator \
               -destination "generic/platform=iOS Simulator" \
               clean build
else
    echo "错误: 未能生成 ${XCODEPROJ_DIR}!"
    exit 1
fi

echo "======================================"
echo " 编译成功! Xcode 工程已准备就绪。"
echo " 工程文件: ${PWD}/${XCODEPROJ_DIR}"
echo "======================================"
