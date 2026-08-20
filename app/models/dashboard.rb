# 完成モックの Dashboard が表示に必要とするデータを定義する。
# 表示のみを担当するため ApplicationRecord は継承しない。
#
# Controller は Dashboard を1つ作って渡すだけで、表示データを組み立てない（DD-006）。
# Task作成に失敗したときは、エラーを持つ Task を new_task として受け取り、
# 成功経路と同じ Dashboard を同じ形で描き直せるようにする。
class Dashboard
  def initialize(user:, new_task: nil)
    @user = user
    @new_task = new_task
  end

  # TodayTasks に出す未完了タスク（正本4章・5章）。
  def today_incomplete
    @today_incomplete ||= @user.tasks.today_incomplete
  end

  # 完了操作をした当日だけ残る完了済みタスク（正本6章）。
  # 画面での配置位置は正本10章で未確定のため、まだ描画はしない（DD-006）。
  def today_completed
    @today_completed ||= @user.tasks.today_completed
  end

  # 作成フォームが使う Task。
  # 失敗時に渡されたものがあればそれを返し、入力とエラーを保ったまま描き直せるようにする。
  def new_task
    @new_task ||= @user.tasks.build
  end
end
