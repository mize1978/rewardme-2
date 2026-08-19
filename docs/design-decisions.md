# RewardMe 2 設計判断の記録

## このドキュメントの目的

実装の過程で確定した構造上の判断を、後から追えるように記録する。

「なぜこの構造になっているのか」を毎回コードやモックから調べ直さなくて済むようにし、
一度決めた構造が知らないうちに崩されるのを防ぐことが目的である。

`docs/before-analysis.md` とは役割を分ける。

* `before-analysis.md` … 旧RewardMeで実際に確認した問題をBeforeとして記録するもの
* `design-decisions.md` … RewardMe 2で確定した構造判断をAfterとして記録するもの

調査の記録と、これから守る判断を同じファイルに混ぜない。

---

## DD-001 MyRoomは画面ではなくDashboard内の領域である

確定日: 2026-08-19
関連: Signup初回施工

### 根拠

完成モック `rewardme_mock_3.html` において、マイルームは独立した画面として存在しない。

* モック内の見出しは「6. ヒーロー（マイルーム）」
* 対応する要素は Dashboard 内のヒーロー領域にある `［ ここに マイルーム画像 / image_tag @room.image ］`
* モックが持つ画面ブロックは Dashboard の10領域のみで、マイルーム単独の画面は存在しない

また `docs/before-analysis.md` のコンポーネント構成案でも、マイルームは

```text
app/components/
  dashboard/
    my_room_component
```

として **Dashboard配下のコンポーネント**に置かれている。

### 決定

* `root` を Dashboard の入口とする（`root "dashboards#show"`）
* MyRoomは将来 `Dashboard::MyRoomComponent` として、このDashboardの中に置く
* Signup成功後の遷移先は `root` = Dashboard とする
* Dashboardは「Signupのための仮ページ」ではなく、完成モックのDashboardを組み上げていく正式な受け皿として扱う

### してはならないこと

* `my_room` 専用のrouteを作る
* `MyRoomsController` を作る
* MyRoomを独立した画面として設計する

### 補足

Signup初回施工の時点では、Dashboardのviewには施工済みの `Shared::SideNavComponent` のみを配置している。
トップバー・ヒーロー・カレンダー・今日のタスクなどの各カードは、後続の施工でこのDashboardへ追加する。

---

## DD-002 Signupは `resource :registration` として単数リソースで表す

確定日: 2026-08-19
関連: Signup初回施工

### 決定

```ruby
resource :registration, only: %i[ new create ]
```

### 理由

* 登録するのは常に自分自身であり、`:id` で対象を選ぶ操作ではないため単数リソースが適切
* Rails 8.1 Authentication Generator が採用している `resource :session` と形が揃う
* `resources :users` にすると、実装しない index / show / update / destroy まで期待される面ができる

### してはならないこと

* `UsersController` を作ってSignupを担わせる

---

## DD-003 認証基盤はGeneratorの構造を使い、生成物は取捨選択する

確定日: 2026-08-19
関連: Signup初回施工

### 決定

Rails 8.1 Authentication Generator を出発点として使うが、生成物を丸ごとは採用しない。

**採用したもの**

* `Session` / `Current` / `Authentication` concern
* `SessionsController`
* `users` / `sessions` のmigration

**採用しなかったもの**

| 対象 | 理由 |
| --- | --- |
| 生成されたView 3枚 | `form_with class: "contents"`（= `display: contents`）を使っており、`before-analysis.md` 2章で排除した手法にあたる。配色もRewardMe 2のデザイントークンと合わない |
| パスワードリセット一式 | Signupの成立に必要ではない。確認メールも導入しないため、メール送信基盤を整備する理由がない |
| `application_cable/connection.rb` | ActionCableを使う機能が確定していない。必要になった時点で追加する |

### 補足

生成されたViewを採用しないため、`sessions/new` は自前で作成している。
`display: contents` は今後も持ち込まない。

`SessionsController` は構造をそのまま採用したが、flashメッセージだけは日本語に置き換えている。
画面に出る文言はすべて日本語にするため（DD-004 と同じ理由）。

---

## DD-004 バリデーションのメッセージは属性ごとに表示する

確定日: 2026-08-19
関連: Signup初回施工

### 決定

エラーは `full_messages` ではなく `errors[:属性名]` を描画する。
そのため各メッセージは、単独で読んで意味が通る日本語の文にする。

例: `"このメールアドレスは既に登録されています"`

### 理由

`full_messages` は属性名を前置するため、
「このメールアドレスは既に登録されています」がそのままの形で表示できない。

### 補足

`has_secure_password` が自前で追加する検証（パスワード未入力・72バイト超・確認用の不一致）は
`message:` オプションでメッセージを差し替えられず、英語のまま表示されてしまう。

そのため `has_secure_password validations: false` で標準検証を止め、
同等の検証を `User` へ明示している。パスワードに関する検証内容とメッセージが
すべて `app/models/user.rb` を読めば分かる状態になる。

`validations: false` が止めるのは検証だけで、`password=` / `authenticate` /
`authenticate_by` / パスワードリセット用トークンの生成は従来どおり動作する。

未入力は `password_digest` の有無で判定している（標準検証と同じ考え方）。
`length` 側は `allow_blank: true` にして、未入力時に2つのエラーが出ないようにしている。

ロケールファイルによる上書きや `default_locale` の変更は行っていない。
i18nの正式導入は別途判断する。

### 将来の施工で必要になること

`validations: false` により、`has_secure_password` の `password_challenge` 検証も止まっている。
これはパスワード変更時に「現在のパスワード」を確認するためのもので、
Signupの時点では使わないため再実装していない。

**パスワード変更機能を施工する際は、`password_challenge` 相当の検証を改めて設計すること。**
