require "rails_helper"

RSpec.describe Dashboard::TaskComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(task: task)) }

  let(:user) { create(:user) }

  describe "未完了のタスク" do
    let(:task) { create(:task, user: user, title: "ゴミ出し") }

    it "タスク名を表示する" do
      expect(rendered.text).to include("ゴミ出し")
    end

    it "完了にする操作を completion の作成へ繋ぐ（DD-005）" do
      form = rendered.css("form").first

      expect(form[:action]).to eq("/tasks/#{task.id}/completion")
      expect(form.css("input[name='_method']")).to be_empty
    end

    it "チェックの中は空にする（モックの ▾ は使わない・DD-008）" do
      expect(rendered.text).not_to include("▾")
      expect(rendered.text).not_to include("✓")
    end

    it "何をするボタンなのかを支援技術へ伝える" do
      expect(rendered.css("[aria-label]").first[:"aria-label"]).to eq("「ゴミ出し」を完了にする")
    end
  end

  describe "完了済みのタスク" do
    let(:task) { create(:task, user: user, title: "ゴミ出し", completed_at: Time.current) }

    it "完了取消の操作へ繋ぐ（DD-005）" do
      form = rendered.css("form").first

      expect(form[:action]).to eq("/tasks/#{task.id}/completion")
      expect(form.css("input[name='_method']").first[:value]).to eq("delete")
    end

    it "チェックに ✓ を表示する" do
      expect(rendered.text).to include("✓")
    end

    it "何をするボタンなのかを支援技術へ伝える" do
      expect(rendered.css("[aria-label]").first[:"aria-label"]).to eq("「ゴミ出し」の完了を取り消す")
    end
  end

  describe "正本と衝突する要素を作らない（DD-008）" do
    let(:task) { create(:task, user: user, title: "ゴミ出し") }

    it "タグ・★・EXP を描かない" do
      expect(rendered.text).not_to include("習慣", "★", "EXP")
    end
  end
end
