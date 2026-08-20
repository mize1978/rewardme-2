require "rails_helper"

RSpec.describe Dashboard do
  let(:user) { create(:user) }

  # 「今日」の判定を伴うため、基準日を固定する。
  around do |example|
    travel_to(Time.zone.local(2026, 8, 21, 12, 0)) { example.run }
  end

  describe "#today_incomplete" do
    it "TodayTasks に出す未完了タスクを返す" do
      overdue = create(:task, user: user, due_on: Date.current - 1)
      today   = create(:task, user: user, due_on: Date.current)
      undated = create(:task, user: user, due_on: nil)

      expect(described_class.new(user: user).today_incomplete.to_a).to eq([ overdue, today, undated ])
    end

    it "期日が未来のもの・完了済みは含めない" do
      future = create(:task, user: user, due_on: Date.current + 1)
      done   = create(:task, user: user, completed_at: Time.current)

      expect(described_class.new(user: user).today_incomplete).not_to include(future, done)
    end

    it "他人のタスクは含めない" do
      other_task = create(:task, user: create(:user), due_on: Date.current)

      expect(described_class.new(user: user).today_incomplete).not_to include(other_task)
    end
  end

  describe "#today_completed" do
    it "当日に完了したタスクを返す" do
      done = create(:task, user: user, completed_at: Time.zone.local(2026, 8, 21, 9, 0))
      create(:task, user: user, completed_at: Time.zone.local(2026, 8, 20, 23, 0))

      expect(described_class.new(user: user).today_completed).to match_array([ done ])
    end

    it "他人のタスクは含めない" do
      other_task = create(:task, user: create(:user), completed_at: Time.current)

      expect(described_class.new(user: user).today_completed).not_to include(other_task)
    end
  end

  describe "#new_task" do
    it "渡されていなければ、そのユーザーの未保存の Task を返す" do
      new_task = described_class.new(user: user).new_task

      expect(new_task).to be_new_record
      expect(new_task.user).to eq(user)
    end

    it "渡されていれば、入力とエラーを保ったまま返す" do
      failed = user.tasks.build(title: "")
      failed.validate

      new_task = described_class.new(user: user, new_task: failed).new_task

      expect(new_task).to equal(failed)
      expect(new_task.errors[:title]).to be_present
    end
  end
end
