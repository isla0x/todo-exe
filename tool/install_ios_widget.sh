#!/usr/bin/env bash
# Xcode 에서 TodoWidget 타깃을 만든 뒤 실행: 위젯 코드를 ios/TodoWidget/ 에 덮어쓴다.
set -euo pipefail
cd "$(dirname "$0")/.."

DEST=ios/TodoWidget
if [ ! -d "$DEST" ]; then
  echo "ios/TodoWidget 폴더가 없어요."
  echo "Xcode 에서 File > New > Target > Widget Extension 으로 이름을 'TodoWidget' 으로 먼저 만들어 주세요."
  exit 1
fi

cp ios_widget/TodoWidget.swift "$DEST/TodoWidget.swift"
cp ios_widget/TodoWidgetBundle.swift "$DEST/TodoWidgetBundle.swift"
cp ios_widget/PrivacyInfo.xcprivacy "$DEST/PrivacyInfo.xcprivacy"
echo "위젯 코드를 $DEST 에 복사했어요."
