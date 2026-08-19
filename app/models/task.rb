# ユーザーが1回こなしたら終わる単発のやること。
# 仕様の正本は docs/product-specs/task.md。
#
# 完了状態は completed_at だけで表す（正本2章）。done 等の別 boolean は持たない。
# 「今日」「期限切れ」の判定は Time.zone（Tokyo）に従う（正本3章）。
class Task < ApplicationRecord
  belongs_to :user

  # 正本2章: title は必須。文字数や文字種の制約は設けない。
  validates :title, presence: { message: "タスク名を入力してください" }

  scope :incomplete, -> { where(completed_at: nil) }
  scope :completed,  -> { where.not(completed_at: nil) }

  # TodayTasks の3つの大分類（正本4章）。いずれも未完了のみを対象とする。
  scope :overdue,   -> { incomplete.where(due_on: ...Date.current) }
  scope :due_today, -> { incomplete.where(due_on: Date.current) }
  scope :undated,   -> { incomplete.where(due_on: nil) }

  # TodayTasks に出す未完了タスク。
  # 期日が未来のものは出さない。期日を過ぎたものは完了・削除・期日変更まで出し続ける（正本5章）。
  #
  # 並びは「期限切れ → 今日が期日 → 日付未設定」の大分類順だけを指定する（正本4章）。
  # 各分類内部の並び順は正本で未確定のため、ここでは一切指定しない。
  # 内部順序は不定なので、呼び出し側もそれに依存しないこと。
  scope :today_incomplete, -> {
    today = Date.current

    incomplete
      .where(due_on: ..today).or(incomplete.where(due_on: nil))
      .order(Arel.sql(sanitize_sql_array([ <<~SQL, { today: today } ])))
        CASE
          WHEN due_on < :today THEN 0
          WHEN due_on = :today THEN 1
          ELSE 2
        END
      SQL
  }

  # TodayTasks に出す完了済みタスク。
  # 完了操作をした当日のあいだだけ残り、日付が変われば対象から外れる（正本6章）。
  # 未完了との並び順は正本で未確定のため、あえて別の scope にしている。
  scope :today_completed, -> { where(completed_at: Date.current.all_day) }

  def completed?
    completed_at.present?
  end

  def incomplete?
    !completed?
  end

  # 期日を過ぎてまだ終わっていない状態（正本5章）。
  def overdue?
    incomplete? && due_on.present? && due_on < Date.current
  end
end
