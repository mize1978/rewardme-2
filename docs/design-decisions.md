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

完成モック（`docs/ui-reference/dashboard-mock.html`）において、マイルームは独立した画面として存在しない。

> 確定当時はこのモックを `~/Downloads/rewardme_mock_3.html` として参照していた。
> 実体をリポジトリへ取り込んだため、参照先を上記へ訂正している（DD-007）。根拠そのものに変更はない。

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

---

## DD-006 Dashboardの表示データは `Dashboard` が定義し、Controllerは組み立てない

確定日: 2026-08-21
関連: Dashboard基盤施工

### 背景

DD-005 で、Task作成に失敗したとき `TasksController` から `dashboards/show` を描画することにした。
このときテンプレートだけを借りるため `DashboardsController#show` は通らない。

Dashboardが空のうちは成立するが、カードを載せた時点で
「成功経路では表示され、422のときだけ壊れる」状態になる。
before-analysis 9章で問題にした「失敗経路が残らない」の再発にあたる。

原因は、Dashboardを描くのに必要なデータの用意が、暗黙に
「`DashboardsController` がやっているはず」という約束になっていることである。
その約束は他のControllerから破れる。

### 決定

Dashboardが必要とするデータは `Dashboard`（`app/models/dashboard.rb`）が定義する。
ControllerはDashboardを1つ作って渡すだけで、表示データを組み立てない。

```ruby
# 表示のみを担当するため ApplicationRecord は継承しない。
class Dashboard
  def initialize(user:, new_task: nil)
```

```ruby
# DashboardsController#show
@dashboard = Dashboard.new(user: Current.user)

# TasksController#create の失敗時。渡すものが1つ増えるだけで、経路は同じ。
@dashboard = Dashboard.new(user: Current.user, new_task: task)
```

### 理由

* Dashboardが何を必要とするかが1ファイルに書かれるため、カードを足したとき両方の経路へ同時に行き渡る。片方だけ壊れる余地がない
* 完成モックのDashboardは10領域あるが、Controller側は領域が増えても1行のまま。before-analysis 5章の「Viewの肥大化」をControllerへ移し替えることにならない
* `Dashboard` 単体でspecを書けるため、カレンダーや成長ルームが載っても、request specを経由せず供給側を検証できる

### 表示に必要なivarは `@dashboard` だけにする

`@task` `@today_incomplete` のようなivarをControllerごとに置かない。
`TasksController#create` では保存対象をローカル変数で扱い、失敗時に `Dashboard` へ渡す。
ivarが2つ以上に増えると、経路ごとに設定漏れが起きる余地が戻ってくる。

### 今回描画しないもの

| 対象 | 理由 |
| --- | --- |
| 完了済みTask | 配置位置が正本10章で未確定。`Dashboard#today_completed` としてデータは定義するが、画面には出さない |
| 作成フォーム・カードの見た目 | Task UI 施工で完成モックへ接続する |

`dashboards/show` に置いた未完了Taskの一覧は、Dashboardが表示データの入口として
成立していることを確かめられる最小の描画である。Task UI 施工で
`Dashboard::TodayTasksComponent` に置き換える。

### Task UI 施工で必ず回収すること

**この暫定の `<ul>` は Task UI 施工の完了時に削除する。**
`Dashboard::TodayTasksComponent` と二重に描画される状態を残さない。

暫定の描画を残したのは、回帰テストが守りたいものが
「`Dashboard.new` が呼ばれたこと」ではなく
「validation failure でも Dashboard が実際に描画可能な状態で返ること」だからである。
呼び出しの有無を検証する形にすると、`@dashboard` はあるのにViewが必要なデータを
描画できない、という本来捕まえたい事故を見逃す。

### してはならないこと

* Controller に `@today_incomplete` などの表示用ivarを個別に置く
* Dashboardの表示データを `DashboardsController` だけが用意する形に戻す
* View から `Current.user.tasks` を直接引く

---

## DD-007 UI正本はリポジトリ内に置く

確定日: 2026-08-21
関連: UI正本の固定

### 背景

Dashboard UI 施工に入る段階で、正本として参照していた
`~/Downloads/rewardme_mock_3.html` が存在しないことが判明した。

問題はファイルが見つからなかったことではなく、**正本をDownloads上の一時的なファイル名で
参照していた**ことである。ダウンロードのたびに `_1` `_2` `_3` と枝番が付くため、
ファイル名は内容を指す識別子として機能しない。名前が変わった時点で、
DD-001 と `application.css` が引いていた根拠への参照が同時に切れた。

### 正本の同定

実体は Artifact `~/Claude/Artifacts/rewardme-target-mock/index.html` に残っていた。
同一物であることは名前ではなく内容で確認している。

* DD-001 が引用した見出し `6. ヒーロー（マイルーム）` と
  `［ ここに マイルーム画像 / image_tag @room.image ］` が一致
* 10領域（デザイントークン / レイアウト骨格 / 共通カード / サイドナビ / トップバー /
  ヒーロー / 成長ツリー / バッジ / リボンBOX / カレンダー / 今日のタスク /
  今週のステータス / お部屋の成長ストリップ）が一致
* `:root` のデザイントークンが `app/assets/tailwind/application.css` の `@theme` と全値一致

### 決定

UI正本を `docs/ui-reference/dashboard-mock.html` としてリポジトリ内に置く。

**このファイルは「見た目の参考」ではなく、Dashboard UI 施工の正本である。**
画面の構造・配置・トークンの根拠を問うときは、このファイルを読む。

取り込みは Artifact の実体をバイト単位でコピーしたものであり、
取り込み時点で SHA-256 の一致を確認している。

```text
取り込み日: 2026-08-21
取り込み元: ~/Claude/Artifacts/rewardme-target-mock/index.html
SHA-256:    7e43f154a9628377a970190395e04ecc22329bf57dca377569e1763ed8fa73c4
```

将来「これは本当にあのモックか」を問うときは、名前ではなくこのハッシュで判定できる。

### してはならないこと

* `~/Downloads/rewardme_mock*.html` を正本として参照する（旧版・枝番が混在しており、内容を特定できない）
* 正本をリポジトリ外のファイル名で参照する記述を新たに書く
* 取り込んだ正本を、施工の都合で書き換える（モックを更新する場合は、新しい実体を同じ手順で取り込み直し、SHA-256を記録し直す）
