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

---

## DD-005 Taskの操作経路はDashboardに属する最小のリソースで表す

確定日: 2026-08-20
関連: Task初回施工②（操作経路）

### 背景

`docs/product-specs/task.md` 10章は、route / API の形と
「完了・完了取消をどの経路で実現するか」を未確定として残している。
Taskモデルは施工済みで、画面と操作経路だけが繋がっていない状態のため、ここで確定させる。

### 決定

```ruby
resources :tasks, only: %i[ create destroy ] do
  resource :completion, only: %i[ create destroy ], module: :tasks
end
```

* 作成 … `POST /tasks`
* 削除 … `DELETE /tasks/:id`
* 完了 … `POST /tasks/:task_id/completion`
* 完了取消 … `DELETE /tasks/:task_id/completion`

### 理由

**index / show / new / edit を作らない**

Taskの一覧も作成フォームも、完成モックでは Dashboard の中にある。
MyRoomと同じく、Taskも独立した画面を持たない（DD-001）。
実装しないアクションを route に出すと、存在しない画面を期待させる面ができる。

**完了は単数リソース `completion` の create / destroy で表す**

完了は「Taskの属性をひとつ書き換える操作」ではなく、「完了という状態を作る／取り消す」操作である。
対象は常にそのTask自身であり `:id` で選ぶものではないため単数リソースが適切で、
ログイン／ログアウトを `resource :session` の create / destroy で表しているのと同じ形になる（DD-002と同じ理由）。

`PATCH /tasks/:id` に completed フラグを送る形にすると、
「タスクの編集」と「完了操作」が同じ経路に同居し、どちらの意図で来た更新かを
paramsから推測することになる。

### 今回入れなかったもの

| 対象 | 理由 |
| --- | --- |
| `update` | 正本5章の「期日変更」は将来必要になるが、今回の施工対象ではない。編集UIが決まった時点で追加する |
| エラーメッセージの表示 | 作成フォームがまだDashboardに無いため、置き場所が無い。フォーム施工と同時に足す |

### 補足

**Taskは必ず `Current.user.tasks` から引く**

`Task.find` で引いてから所有者を確かめる形にはしない。
他人のTaskはそもそも見つからず `RecordNotFound` になる（正本1章）。

**作成に失敗したときはDashboardを422で再描画する**

Signupが `render :new, status: :unprocessable_content` で失敗経路を残しているのと同じ形にする（DD-003）。
リダイレクトで握り潰すと、before-analysis 9章で問題としている「失敗経路が残らない」状態に戻る。
エラーの描画自体は上記のとおりフォーム施工で足すため、現時点では
「作成されないこと」と「422で戻ること」だけが担保される。

**同じ操作を繰り返しても完了時刻を書き換えない**

完了済みのTaskへ再度 `POST completion` が来ても `completed_at` を更新しない。
更新してしまうと、正本6章の「完了操作をした当日だけ TodayTasks に残る」判定の基準日が
ユーザーの操作なしにずれる。未完了へ `DELETE completion` が来た場合も同様に何もしない。

### してはならないこと

* `PATCH /tasks/:id` に completed 相当のフラグを渡して完了状態を変える
* `TasksController` に `complete` / `uncomplete` などのアクションを生やす
* `Current.user` を経由せず `Task.find` で引く
