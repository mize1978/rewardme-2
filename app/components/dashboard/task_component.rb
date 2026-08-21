# 今日のタスクカードの1行（完成モックの .task）。
#
# 表示責務のみを持つ。DBアクセスも完了判定のルールも持たず、渡された Task を描くだけ。
# 完了トグルは DD-005 の completion（POST / DELETE）へ繋ぐ。
#
# モックの .chk はサイズ・位置・質感を維持し、中の記号だけ変えている。
# 未完了は空（枠のみ）、完了は ✓。モックの ▾ は「開く」意味を持たないため使わない（DD-008）。
# 名前空間の Dashboard は app/models/dashboard.rb のクラス。
# 既存の Tasks::CompletionsController と同じコンパクト記法で定義する。
class Dashboard::TaskComponent < ViewComponent::Base
  # @param task [Task] 描画する Task
  def initialize(task:)
    @task = task
  end

  attr_reader :task

  # 完了済みなら完了取消、未完了なら完了。経路はどちらも同じ単数リソース（DD-005）。
  def toggle_method
    task.completed? ? :delete : :post
  end

  def toggle_label
    task.completed? ? "「#{task.title}」の完了を取り消す" : "「#{task.title}」を完了にする"
  end
end
