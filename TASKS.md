# NectarView アップデートタスク

## A. バグ修正・不具合

- [x] A-1: AppDelegateのファイル開き処理を修正（脆弱なNSHostingViewキャストを除去、onOpenURLに統一）
- [x] A-2: Editメニュー削除の修正（SwiftUIのCommandGroup(replacing: .textEditing)に移行）
- [x] A-3: 画像プリフェッチを有効化（currentIndex didSetからpreloadAdjacentImagesを呼び出し、ZIP/PDF対応）
- [x] A-4: PDF表示のRetina対応（NSBitmapImageRepによる高解像度レンダリング）

## B. 非推奨API・デッドコード

- [x] B-5: `@Environment(\.presentationMode)` → `@Environment(\.dismiss)` に移行
- [x] B-6: `UserDefaults.standard.synchronize()` を削除
- [x] B-7: 未使用の `import SwiftData` を削除
- [x] B-8: 未使用のSDWebImageSwiftUI依存を削除

## C. ローカライズ

- [x] C-9: BookmarkListViewのハードコード英語文字列をローカライズ

## D. パフォーマンス・設計改善

- [x] D-10: マウストラッキングをTimerポーリングからonContinuousHoverに変更
- [x] D-11: KeyboardHandlerの生キーコードをわかりやすい定数に置換

## E. 依存関係の更新

- [x] E-12: SDWebImage依存を削除（B-8と連動）
- [x] E-13: ZIPFoundation を 0.9.19 → 0.9.20 に更新

## F. テスト・品質

- [x] F-14: 空のNectarViewTests.swiftを削除
- [x] F-15: SwiftLintルールの見直し・有効化（現実的な閾値設定）
- [x] F-16: CI/CD構成の追加（GitHub Actions: build-and-test.yml）

## G. デプロイメント

- [x] G-17: デプロイメントターゲットを14.0に統一
- [x] G-18: 不要なネットワーク権限(network.client)を削除
