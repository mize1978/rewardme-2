Task プロダクト仕様（正本）v1.0

Q1〜12・Q21・Q22 確定内容の統合版

1. 前提
RewardMe 2 はマルチユーザーである。
Task は必ず1人の User に属する。
User / Authentication は施工済み。users テーブルが存在し、認証済み Current.user を取得できる。
2. データ構造
```
tasks
├─ user_id       NOT NULL + FK
├─ title         NOT NULL
├─ due_on        nullable date
├─ completed_at  nullable datetime
└─ timestamps
```
completed_at を完了状態の single source of truth とする。done 等の別 boolean は持たない。
title は必須。未入力・空文字では Task を作成できない。それ以上の文字数制約は現時点で設けない。絵文字のみ等も禁止しない。
due_on は日付未設定（nullable）を許容する。
priority / category は初回 Task テーブルに含めない。RewardMe 2 での機能採用自体が未確定のため。
Task ごとの報酬額カラム（coin_reward 等）は持たない。
3. 日付・時刻の判定基準
「今日」「当日」「期限切れ」の判定は JST（Asia/Tokyo）基準とする。
Rails アプリケーションの Time.zone は Tokyo を基準とする。
日付判定には Time.zone.today / Date.current 等、Rails の Time.zone を尊重する API を使用する。Time.now や UTC 前提の直接比較で「今日」を判定しない。
completed_at に基づく「完了当日」判定も JST 基準で行う。
due_on は date 型のまま保持し、JST の「今日」と比較する。
ユーザーごとのタイムゾーン対応は現時点では導入しない。
4. TodayTasks への表示対象
日付未設定の Task は「いつでもやってよい Task」として常時 TodayTasks に表示する。
日付ありの Task は、指定日当日に TodayTasks へ表示する。
表示対象は件数によって除外しない。上限（例：最新10件のみ）を設けない。
未完了 Task の大分類順

基本順序は次の通り。

期限切れ → 今日が期日 → 日付未設定
priority によってこの大分類の順序を逆転させない。
各グループ内部の並び順は未確定。
完了済み Task の配置位置は未確定。
5. 期日超過・未完了 Task の扱い
期日を過ぎても未完了であれば、Task を消さない。
TodayTasks 内に「期限切れ」として表示し続ける。
元の期日がわかる状態を保つ。期日は自動変更しない。
完了した場合は「6. 完了済み Task の表示」に従う。
日数・件数による自動的な表示終了は設けない。ユーザーが「完了」「削除」「期日変更」のいずれかを行うまで残る。古いことだけを理由に RewardMe 側で自動除外しない。
6. 完了・完了取消
完了時、completed_at に完了日時を記録する。
完了取消時、completed_at を nil に戻す。
完了済み Task の表示は、完了操作をした当日（JST基準）の TodayTasks にのみ「完了済み」として残る。日付が変われば TodayTasks の表示対象から外れる。Task 自体は削除されず、completed_at も保持される。
日付未設定 Task を完了しても、翌日に未完了へ自動的に戻さない。
完了済み Task を未完了へ戻すことができる（完了取消）。
完了/未完了の toggle は UI 上で可能とする。
完了取消時のコイン・実績等への影響は、今回のスコープでは決定しない。
7. 作成・削除
Task 作成数に上限を設けない。
1日の完了数にも上限を設けない。
Task 作成数・完了数は、ハート等の他機能と接続しない。回数制限・カウンタ・そのための validation を Task 側に持たせない。
未完了・完了済みのどちらも、ユーザー自身が削除できる。
削除時の実績・コイン履歴等の扱いは別ドメインで判断する。
8. Task と Habit の境界
Task は「1回完了したら終了する単発のやること」である。
recurrence / repeat interval / 自動再生成等の繰り返し機構は Task に持たせない。繰り返しは Habit ドメインの責務とする。
現段階で Task と Habit の関連は設計しない。
9. 報酬（Task 側の制約のみ）
Task 完了時の報酬額は Task ごとに変えない。priority / category / 期日等によっても変動させない。
現時点の基準は「1 Task 完了＝10コイン」。
ユーザーが Task 作成時に報酬額を指定する機能は持たせない。
tasks テーブルに報酬額のカラムは持たない。固定10コインの管理方法・Task 完了との接続・報酬履歴は別途設計する。
10. 今回のスコープに含まれないもの（未確定・別ドメイン）
UI 上の見せ方・色・配置
大量件数時の表示方法（折りたたみ・スクロール等）
各グループ内部の並び順
完了済み Task の配置位置
route / API の形、完了・完了取消をどの経路で実現するか
Service / Command 等の実装方式
コイン・実績・成長等の副作用（完了時・完了取消時とも）
priority / category の機能採用可否
Task と Habit の関連設計
将来機能のための拡張
パフォーマンス最適化・index 設計
ユーザーごとのタイムゾーン対応
11. Q1〜12・Q21・Q22 との照合

上記正本は、Q1〜12・Q21・Q22 の確定内容をすべて反映しており、矛盾・欠落は確認されませんでした。Before仕様（旧RewardMeのpriority 3種/category 6種など）は参照のみで、本正本には含めていません。
