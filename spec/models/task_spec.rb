require "rails_helper"

RSpec.describe Task, type: :model do
  # JST の朝8:30。このときUTCではまだ前日23:30なので、
  # 「今日」をJSTで見ているかUTCで見ているかがはっきり分かれる。
  let(:jst_morning) { Time.zone.local(2026, 8, 19, 8, 30) }

  around { |example| travel_to(jst_morning) { example.run } }

  describe "所属" do
    it "User に属さない Task は作れない" do
      task = build(:task, user: nil)

      expect(task).to be_invalid
    end
  end

  describe "タスク名の検証" do
    it "未入力なら無効になる" do
      task = build(:task, title: nil)

      expect(task).to be_invalid
      expect(task.errors[:title]).to include("タスク名を入力してください")
    end

    it "空文字なら無効になる" do
      expect(build(:task, title: "")).to be_invalid
    end

    it "長いタスク名でも有効になる" do
      expect(build(:task, title: "あ" * 500)).to be_valid
    end

    it "絵文字だけでも有効になる" do
      expect(build(:task, title: "🎀")).to be_valid
    end
  end

  describe "日付の判定基準" do
    it "JST を基準に「今日」を決める" do
      # UTC では前日になっている状況で、Date.current が JST の日付を返すこと
      expect(Time.zone.name).to eq("Tokyo")
      expect(Date.current).to eq(Date.new(2026, 8, 19))
      expect(Time.current.utc.to_date).to eq(Date.new(2026, 8, 18))
    end
  end

  describe "完了状態" do
    it "completed_at が入っていれば完了とみなす" do
      task = build(:task, completed_at: Time.current)

      expect(task).to be_completed
      expect(task).not_to be_incomplete
    end

    it "completed_at が nil なら未完了とみなす" do
      task = build(:task, completed_at: nil)

      expect(task).to be_incomplete
      expect(task).not_to be_completed
    end

    it "完了を取り消すと未完了に戻る" do
      task = create(:task, completed_at: Time.current)

      task.update!(completed_at: nil)

      expect(task.reload).to be_incomplete
    end
  end

  describe "#overdue?" do
    it "期日を過ぎた未完了は期限切れになる" do
      expect(build(:task, due_on: Date.current - 1)).to be_overdue
    end

    it "今日が期日なら期限切れではない" do
      expect(build(:task, due_on: Date.current)).not_to be_overdue
    end

    it "日付未設定なら期限切れにならない" do
      expect(build(:task, due_on: nil)).not_to be_overdue
    end

    it "期日を過ぎていても完了済みなら期限切れではない" do
      task = build(:task, due_on: Date.current - 1, completed_at: Time.current)

      expect(task).not_to be_overdue
    end
  end

  describe "スコープ" do
    let(:user) { create(:user) }

    let!(:overdue)   { create(:task, user: user, due_on: Date.current - 3) }
    let!(:today)     { create(:task, user: user, due_on: Date.current) }
    let!(:undated)   { create(:task, user: user, due_on: nil) }
    let!(:future)    { create(:task, user: user, due_on: Date.current + 1) }
    let!(:done)      { create(:task, user: user, due_on: Date.current, completed_at: Time.current) }

    describe ".incomplete / .completed" do
      it "completed_at の有無で分かれる" do
        expect(Task.incomplete).to match_array([ overdue, today, undated, future ])
        expect(Task.completed).to match_array([ done ])
      end
    end

    describe ".overdue / .due_today / .undated" do
      it "未完了を3つの大分類へ分ける" do
        expect(Task.overdue).to match_array([ overdue ])
        expect(Task.due_today).to match_array([ today ])
        expect(Task.undated).to match_array([ undated ])
      end

      it "完了済みはどの分類にも入らない" do
        expect(Task.overdue + Task.due_today + Task.undated).not_to include(done)
      end
    end

    describe ".today_incomplete" do
      it "期限切れ・今日が期日・日付未設定を対象にする" do
        expect(Task.today_incomplete).to include(overdue, today, undated)
      end

      it "期日が未来のものは対象にしない" do
        expect(Task.today_incomplete).not_to include(future)
      end

      it "完了済みは対象にしない" do
        expect(Task.today_incomplete).not_to include(done)
      end

      it "期限切れ → 今日が期日 → 日付未設定 の順に並べる" do
        # 各分類が1件ずつなので、この比較は分類順だけを見ており内部順序には依存しない。
        expect(Task.today_incomplete.to_a).to eq([ overdue, today, undated ])
      end

      it "作成順が並び順と逆でも、大分類順で並べ替える" do
        # undated → today → overdue の順に作っても、出力は大分類順になること
        Task.delete_all
        u = create(:task, user: user, due_on: nil)
        t = create(:task, user: user, due_on: Date.current)
        o = create(:task, user: user, due_on: Date.current - 5)

        expect(Task.today_incomplete.to_a).to eq([ o, t, u ])
      end

      it "各分類が同数以上あっても、分類の境界どおりに並ぶ" do
        # 内部順序は正本で未確定なので、ここでは分類の境界だけを見る。
        # match_array は順不同で比較するため、分類内部の順序には依存しない。
        Task.delete_all
        overdue_group = [ create(:task, user: user, due_on: Date.current - 3),
                          create(:task, user: user, due_on: Date.current - 1) ]
        today_group   = [ create(:task, user: user, due_on: Date.current),
                          create(:task, user: user, due_on: Date.current) ]
        undated_group = [ create(:task, user: user, due_on: nil),
                          create(:task, user: user, due_on: nil) ]

        result = Task.today_incomplete.to_a

        expect(result.size).to eq(6)
        expect(result[0..1]).to match_array(overdue_group)
        expect(result[2..3]).to match_array(today_group)
        expect(result[4..5]).to match_array(undated_group)
      end

      it "期日を過ぎても、完了・削除・期日変更をするまで残り続ける" do
        old = create(:task, user: user, due_on: Date.current - 365)

        expect(Task.today_incomplete).to include(old)
      end
    end

    describe ".today_completed" do
      it "当日に完了したものだけを対象にする" do
        expect(Task.today_completed).to match_array([ done ])
      end

      it "前日に完了したものは対象にしない" do
        yesterday_done = create(:task, user: user, completed_at: Time.zone.local(2026, 8, 18, 23, 30))

        expect(Task.today_completed).not_to include(yesterday_done)
      end

      it "JST の当日0時台に完了したものも対象にする" do
        # UTC では前日15:30にあたる時刻。UTC基準で判定していると取りこぼす。
        midnight_done = create(:task, user: user, completed_at: Time.zone.local(2026, 8, 19, 0, 30))

        expect(Task.today_completed).to include(midnight_done)
      end

      it "未完了は対象にしない" do
        expect(Task.today_completed).not_to include(overdue, today, undated)
      end
    end

    describe "ユーザーごとの分離" do
      it "関連から辿ると自分の Task だけを返す" do
        other = create(:user)
        other_task = create(:task, user: other, due_on: Date.current)

        expect(user.tasks.today_incomplete).not_to include(other_task)
        expect(other.tasks.today_incomplete).to match_array([ other_task ])
      end
    end
  end
end
