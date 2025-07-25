# 大容量ファイル整理スクリプト for Linux - 要件定義書

## 1. プロジェクト概要

### 目的

Linuxでディスク容量が不足した際に、サイズが大きな不要ファイルを迅速に発見し、ユーザーが選択して削除できるスクリプトを開発する。

### 対象環境

- OS: Ubuntu 22.04以降
- 実行環境: bash
- 権限: 一般ユーザー権限（管理者権限不要）
- インストール: 不要（単体実行可能）

## 2. 機能要件

### 2.1 ファイル検索機能

#### 検索対象

- **範囲**: ユーザーが手動で選択したドライブまたはフォルダ
- **ファイル種別**: 全てのファイル種類を対象
  - 一般ファイル
  - 一時ファイル
  - キャッシュファイル
  - システムファイル（アクセス可能な範囲）

#### サイズ条件

- **閾値選択**: 複数の事前定義された閾値から選択
  - 50MB以上
  - 100MB以上（推奨デフォルト）
  - 500MB以上
  - 1GB以上
  - その他の閾値も設定可能

### 2.2 表示機能

#### インターフェース

- **形式**: CUI（コマンドラインインターフェース）
- **表示項目**:
  - ファイルパス（フルパス）
  - ファイルサイズ（人間が読みやすい形式）
  - 更新日時
- **ソート**: ファイルサイズの大きい順

#### 進行状況表示

- 検索中の進行状況を表示
- 検索済みファイル数の表示
- 検索中のフォルダパスの表示

### 2.3 選択・削除機能

#### ファイル選択

- **個別選択**: チェックボックス形式での個別ファイル選択
- **一括選択**:
  - 全選択機能
  - 全解除機能

#### 削除実行

- **削除方法**: ごみ箱に移動
- **確認**: 簡単な最終確認ダイアログ
- **対象**: 選択されたファイルのみ

### 2.4 設定管理機能

#### 初期値保存

- 前回選択したフォルダパス
- 前回選択したサイズ閾値
- 設定ファイル形式: JSON または INI
- 設定ファイル場所: スクリプトと同じディレクトリ

## 3. 非機能要件

### 3.1 パフォーマンス

- **負荷制御**: 他のPC作業に影響しない軽い負荷
- **高速化**: 可能な限りの検索速度最適化
- **メモリ使用量**: 適切なメモリ管理

### 3.2 安全性

- **削除保護**: ごみ箱移動のため、特別な保護機能は不要
- **確認機能**: 削除前の簡単な確認のみ
- **ログ機能**: 不要

### 3.3 ユーザビリティ

- **操作性**: 直感的なCUI操作
- **エラーハンドリング**: 適切なエラーメッセージ表示
- **ヘルプ機能**: 基本的な使用方法の表示

## 4. 除外機能

以下の機能は今回の要件に含まない：

- GUIインターフェース
- 検索結果のファイル保存機能
- 定期実行・スケジュール機能
- 詳細なログ記録機能
- ファイル種別別のフィルタリング
- 重要ファイルの特別な保護機能
- バックアップ機能
- 完全削除機能

## 5. 技術仕様

### 5.1 実装言語

- Bash

### 5.2 依存関係

- Ubuntu標準機能のみ使用
- 外部ライブラリ不要

### 5.3 ファイル構成

```
FileCleanupTool.bash    # メインスクリプト
config.json            # 設定ファイル（自動生成）
README.md              # 使用方法説明書
```

## 6. 運用要件

### 6.1 配布・実行

- 単一のbashファイルとして配布
- ターミナルから直接実行
- 実行ポリシーの制限に対する対応方法を文書化

### 6.2 保守性

- コードの可読性を重視
- 適切なコメント記述
- 設定値の変更が容易

## 7. 成功基準

- 指定したサイズ以上のファイルを5分以内に検索完了（一般的なPC環境）
- ユーザーが迷わずファイル選択・削除を実行可能
- 他のアプリケーションの動作に影響を与えない
- 管理者権限なしで正常動作する

-----

**作成日**: 2025年6月16日  
**バージョン**: 1.0  
**作成者**: ユーザー要件ヒアリングによる
