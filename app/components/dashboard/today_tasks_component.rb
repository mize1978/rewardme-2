# 今日のタスクカード（完成モックの .tasks.card）。
#
# 描くのは未完了タスクだけで、完了済みは配置が正本10章で未確定のため描かない（DD-008）。
# 表示責務のみを持ち、データは引数で受け取る（DD-006）。
# 名前空間の Dashboard は app/models/dashboard.rb のクラス。
# 既存の Tasks::CompletionsController と同じコンパクト記法で定義する。
class Dashboard::TodayTasksComponent < ViewComponent::Base
  # @param tasks [Enumerable<Task>] 今日出す未完了タスク
  # @param new_task [Task] 作成フォームが使う Task。エラーを持つ場合はフォームを開いた状態で描く。
  def initialize(tasks:, new_task:)
    @tasks = tasks
    @new_task = new_task
  end

  attr_reader :tasks, :new_task

  # 作成に失敗した直後は、入力値とエラーを見せるためフォームを開いた状態で描く。
  # 開閉状態はサーバが決め、JSの状態復元には依存しない（DD-008）。
  def form_open?
    new_task.errors.any?
  end
end
