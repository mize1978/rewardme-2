require "rails_helper"

RSpec.describe Dashboard::TodayTasksComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(tasks: tasks, new_task: new_task)) }

  let(:user) { create(:user) }
  let(:tasks) { [] }
  let(:new_task) { user.tasks.build }

  describe "カードの骨格" do
    it "見出しを表示する" do
      expect(rendered.css("h2").text).to include("今日のタスク")
    end

    it "追加ボタンを表示する" do
      expect(rendered.text).to include("＋ 追加")
    end

    it "ミッション行は作らない（別ドメイン・DD-008）" do
      expect(rendered.text).not_to include("ミッション")
    end
  end

  describe "タスクの一覧" do
    let(:tasks) { [ create(:task, user: user, title: "ゴミ出し") ] }

    it "渡されたタスクを描画する" do
      expect(rendered.text).to include("ゴミ出し")
    end

    it "1つのタスクを1回だけ描画する" do
      expect(rendered.text.scan("ゴミ出し").size).to eq(1)
    end
  end

  describe "タスクが無いとき" do
    it "空であることを伝える" do
      expect(rendered.text).to include("今日のタスクはまだありません")
    end
  end

  describe "作成フォーム" do
    it "作成経路へ送る（DD-005）" do
      form = rendered.css("form").first

      expect(form[:action]).to eq("/tasks")
      expect(form[:method]).to eq("post")
    end

    it "受け取るのは タスク名 と 期日 だけ" do
      expect(rendered.css("input[name='task[title]']")).to be_present
      expect(rendered.css("input[name='task[due_on]']")).to be_present
      expect(rendered.css("input[name='task[completed_at]']")).to be_empty
    end

    it "エラーが無ければ閉じた状態で描く" do
      expect(rendered.css("[data-task-form-target='panel']").first.attributes).to have_key("hidden")
      expect(rendered.css("[data-task-form-open-value]").first[:"data-task-form-open-value"]).to eq("false")
    end
  end

  describe "作成に失敗した直後" do
    let(:new_task) do
      user.tasks.build(title: "").tap(&:validate)
    end

    it "フォームを開いた状態で描く（DD-008）" do
      expect(rendered.css("[data-task-form-open-value]").first[:"data-task-form-open-value"]).to eq("true")
    end

    it "エラーメッセージを属性ごとに表示する（DD-004）" do
      expect(rendered.text).to include("タスク名を入力してください")
    end

    it "入力値を保持する" do
      component = described_class.new(tasks: [], new_task: user.tasks.build(title: "書きかけ").tap(&:validate))

      expect(render_inline(component).css("input[name='task[title]']").first[:value]).to eq("書きかけ")
    end

    it "JS が動かなくてもフォームが見えるよう、hidden を付けない" do
      # 開いた状態をサーバが描かず Stimulus の復元に頼ると、JS無効時にエラーが見えなくなる。
      expect(rendered.css("[data-task-form-target='panel']").first.attributes).not_to have_key("hidden")
    end
  end
end
