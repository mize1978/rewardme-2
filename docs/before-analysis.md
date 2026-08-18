# RewardMe Before Analysis

## 1. このドキュメントの目的

RewardMe 2は、旧RewardMeを単純に作り直すプロジェクトではない。

旧RewardMeは、プログラミング学習初期に限られた知識から開発を開始し、その後、実際に公開・運用しながら機能を追加してきた。

その結果、開発初期には見えなかった設計・保守上の問題が、機能拡張とともに明確になった。

このドキュメントでは、旧RewardMeで実際に確認した問題をBeforeとして記録し、それをRewardMe 2でどのように改善するかを整理する。

旧RewardMeのリポジトリはBeforeの正本として保存し、RewardMe 2の開発を理由に変更しない。

---

## 2. CSSの継ぎ足しによる複雑化

### Before

旧RewardMeでは、ダッシュボード調整用の

`app/assets/stylesheets/zz_dashboard_grid.css`

が約1,454行まで増加していた。

ファイル内ではv1〜v23まで段階的な調整が積み重なり、ダッシュボードだけでなくミニゲーム等のスタイルも混在していた。

また、

```css
display: contents !important;
```

や、

```css
:has(...)
```

などを利用し、既存のHTML構造を維持したままCSS側から表示構造を変更する実装も存在した。

### Problem

見た目を変更するたびに既存CSSへ追加の調整を重ねる構造になり、

* どのCSSが最終的に有効なのか分かりにくい
* 変更の影響範囲を判断しにくい
* HTML構造と実際の画面構造が一致しない
* 一箇所の修正が別の箇所へ影響しやすい

という状態になった。

### RewardMe 2

* Tailwind CSSを中心に構築する
* 後乗せCSSによる上書きを常態化させない
* `!important` の積み重ねで解決しない
* UI単位でスタイルの責務を限定する
* DOM構造と画面構造をできるだけ一致させる

---

## 3. `zoom` によるレイアウト調整

### Before

旧RewardMeでは完成イメージの寸法へ合わせるため、

```css
body {
  zoom: 0.9;
}
```

という調整が存在した。

### Problem

画面全体を縮小して帳尻を合わせるため、個々のレイアウト設計上の問題を隠してしまう。

また、ブラウザや画面サイズによって表示結果が変わる可能性があり、レスポンシブ設計との整合性も悪くなる。

### RewardMe 2

`zoom` による全体調整は使用せず、Grid / Flexbox / Tailwindのレスポンシブ機能を利用して、各領域のサイズと配置を明示的に設計する。

---

## 4. DOM構造と画面構造の乖離

### Before

旧RewardMeでは、

* サイドバー
* リボンBOX
* 今日の獲得アイテム
* ナビゲーション
* center-bottom
* 各種カード

などが、既存構造へ段階的に追加されていた。

さらに `display: contents` や `grid-area` によって表示位置を変更していたため、HTMLを読んだだけでは画面上の配置を把握しにくい状態だった。

### Problem

画面の構造を理解するために、HTMLだけでなく複数のCSSルールを追う必要があった。

そのため、新しいUIを追加・移動する際の影響範囲が大きくなった。

### RewardMe 2

完成モックをUI設計の正本とする。

画面上の領域とDOM構造を対応させ、

「なぜこのカードがここに表示されているのか」

をコードから追える構造にする。

既存機能を残すために完成モックを変更することはしない。

---

## 5. Viewの肥大化

### Before

旧RewardMeの `_header.html.erb` は約264行あり、

* デスクトップヘッダー
* モバイルヘッダー
* 通知
* プロフィール
* BGM
* その他UI

が同じPartial内に存在していた。

### Problem

1ファイルが複数のUI責務を持つことで、

* 修正箇所を探しにくい
* 条件分岐が増える
* UI単位でテストしにくい
* 他画面で再利用しにくい

という問題が発生した。

### RewardMe 2

ViewComponentを導入し、基本的にUIカード単位でコンポーネント化する。

例：

```text
app/components/
  dashboard/
    my_room_component
    status_bar_component
    calendar_component
    today_tasks_component
    room_growth_component
    ribbon_growth_chain_component
    badge_collection_component
    weekly_stats_component
  shared/
    side_nav_component
```

原則として、

**1カード = 1コンポーネント**

を目安にする。

---

## 6. Userモデルへの責務集中

### Before

旧RewardMeの `app/models/user.rb` は約11,000文字まで増加していた。

Userモデルには認証に加えて、

* レベル
* EXP
* 部屋の成長
* キャラクター進化
* コイン
* その他RewardMe固有ロジック

などの責務が集中していた。

### Problem

Userに直接関係するデータと、RewardMe独自のゲーム・成長ロジックの境界が曖昧になった。

機能追加のたびにUserモデルへ処理を追加しやすくなり、変更の影響範囲も広がった。

### RewardMe 2

Userモデルへすべてのロジックを集約しない。

候補として、

```text
app/models/
  user.rb
  ribbon_growth.rb
  room.rb
  task.rb
  habit.rb

app/services/
  ribbon_growth_calculator.rb
  task_completion_service.rb
```

などへ責務を分離する。

具体的なクラス構成は実装前に決め打ちせず、必要になった段階で責務を確認して設計する。

---

## 7. JavaScript Controllerの巨大化

### Before

旧RewardMeの `match_game_controller.js` は約24,289文字まで増加していた。

1つのStimulus Controllerが多数の処理を担当していた。

### Problem

処理同士の依存関係が増え、

* 一部分だけ変更しにくい
* 状態管理を追いにくい
* テストしにくい
* 別機能への再利用が難しい

状態になった。

### RewardMe 2

基本方針を、

**1 Stimulus Controller = 1責務**

とする。

Controllerの行数だけで機械的に分割するのではなく、「何を担当するControllerなのか」を一文で説明できる単位にする。

---

## 8. 開発用コードの残存

### Before

旧RewardMeでは `data-mg-fx` など、調査用URLパラメータやデバッグ目的のコードが本番コード内に残っていた。

### Problem

一時的な調査コードと正式な機能の境界が曖昧になる。

時間が経つと「削除してよいコードなのか」を判断しにくくなる。

### RewardMe 2

開発用機能と本番機能を明確に分離する。

一時的な調査コードは、目的を達成した段階で削除する。

---

## 9. 失敗経路のテスト不足

### Before

旧RewardMeでは正常に操作できる経路を中心に確認していた。

その結果、後から、

* ユーザー登録失敗
* ログイン失敗
* バリデーション失敗

など、「処理が成功しなかった場合」の画面で不具合が発見された。

### Problem

成功系だけを確認していると、通常操作では発見しにくい状態にバグが残る。

特にフォームでは、validation error時に同じ画面を再描画した際だけ発生する問題がある。

### RewardMe 2

RSpecを開発初期から導入する。

成功系だけでなく、

* validation failure
* unauthorized access
* redirect
* error rendering
* invalid parameters

などの失敗経路もテスト対象とする。

「正常に動いた」だけを完成条件にしない。

---

## 10. 既存機能を残すこと自体が目的になっていた

### Before

旧RewardMeのリニューアルを検討した際、既存の「今日のリボンBOX」などを、

* サイドバーから中央へ移動する
* 右下へ移動する
* デザインだけ変更する

といった方法で残そうとしていた。

しかし完成モックには、そもそもリボンBOXが存在しなかった。

### Problem

「すでに実装されているから残す」という判断をすると、新しい設計が古い構造に引っ張られる。

### RewardMe 2

完成モックとRewardMe 2の目的を基準に判断する。

旧版に存在すること自体は、RewardMe 2へ機能を移植する理由にしない。

そのため、

* 今日のリボンBOX
* 今日の獲得アイテムパネル
* COMING SOON状態のお部屋デコレーション

なども、必要性を改めて判断する。

---

## 11. RewardMe 2で守る設計原則

### UI

完成モックを正本とする。

### CSS

Tailwind中心で構築し、後乗せCSSによる上書きを常態化させない。

### View

巨大ERBを避け、責務単位でViewComponentへ分割する。

### Model

UserへRewardMe固有ロジックを集中させない。

### JavaScript

1 Stimulus Controller = 1責務を基本とする。

### Test

成功経路と失敗経路の両方を最初からテストする。

### Git

工程を小さく分け、意味のある単位でcommitする。

### Development

変更前に影響範囲を確認し、一度に複数の目的を混ぜない。

---

## 12. Beforeを残す理由

旧RewardMeは失敗作ではない。

学習初期に作り始めたアプリを実際に公開し、機能を増やし続けたことで、設計・保守・テストの問題を実体験として発見できた。

RewardMe 2では、その経験をもとに、

**「動くものを作る」から「変更し続けられる構造を作る」へ進む。**

その過程を比較できるよう、旧 `rewardme` をBeforeとして保存し、新しい `rewardme-2` をAfterとして構築する。

Beforeを消さずに残すこと自体が、RewardMe 2の設計意図の一部である。
