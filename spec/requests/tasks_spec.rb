require "rails_helper"

RSpec.describe "Tasks", type: :request do
  let(:user) { create(:user) }

  def sign_in(as:)
    post session_path, params: { email_address: as.email_address, password: "password" }
  end

  describe "POST /tasks" do
    it "未ログインでは作成できず、ログイン画面へ誘導される" do
      expect {
        post tasks_path, params: { task: { title: "ゴミ出し" } }
      }.not_to change(Task, :count)

      expect(response).to redirect_to(new_session_path)
    end

    context "ログイン済み" do
      before { sign_in(as: user) }

      it "自分の Task として作成され、Dashboard へ戻る" do
        expect {
          post tasks_path, params: { task: { title: "ゴミ出し", due_on: Date.current } }
        }.to change(user.tasks, :count).by(1)

        task = user.tasks.last
        expect(task.title).to eq("ゴミ出し")
        expect(task.due_on).to eq(Date.current)
        expect(task).to be_incomplete
        expect(response).to redirect_to(root_path)
      end

      it "期日なしでも作成できる（正本2章）" do
        post tasks_path, params: { task: { title: "いつでもやること" } }

        expect(user.tasks.last.due_on).to be_nil
      end

      it "title が空なら作成されず、422 で戻る" do
        expect {
          post tasks_path, params: { task: { title: "" } }
        }.not_to change(Task, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "title が空で失敗したら、入力値とエラーを保ったままフォームを開いて返す" do
        post tasks_path, params: { task: { title: "", due_on: "2026-08-25" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("タスク名を入力してください")
        expect(response.body).to include('data-task-form-open-value="true"')
        expect(response.body).to include('value="2026-08-25"')
      end

      it "title が空で失敗しても、Dashboard の今日のタスクが描画される" do
        # 表示データを Controller ごとに組み立てていると、成功経路では出て
        # 422 のときだけ壊れる状態になる。それを検出するための回帰テスト（DD-006）。
        create(:task, user: user, title: "ゴミ出し", due_on: Date.current)

        post tasks_path, params: { task: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("ゴミ出し")
        expect(Nokogiri::HTML(response.body).text.scan("ゴミ出し").size).to eq(1)
      end

      it "completed_at はユーザーからの入力で決まらない" do
        post tasks_path, params: { task: { title: "ゴミ出し", completed_at: Time.current } }

        expect(user.tasks.last).to be_incomplete
      end

      it "他人の Task としては作成できない" do
        other = create(:user)

        post tasks_path, params: { task: { title: "ゴミ出し", user_id: other.id } }

        expect(user.tasks.last.user).to eq(user)
        expect(other.tasks).to be_empty
      end
    end
  end

  describe "DELETE /tasks/:id" do
    before { sign_in(as: user) }

    it "未完了の Task を削除できる（正本7章）" do
      task = create(:task, user: user)

      expect {
        delete task_path(task)
      }.to change(user.tasks, :count).by(-1)

      expect(response).to redirect_to(root_path)
    end

    it "完了済みの Task も削除できる（正本7章）" do
      task = create(:task, user: user, completed_at: Time.current)

      expect {
        delete task_path(task)
      }.to change(user.tasks, :count).by(-1)
    end

    it "他人の Task は削除できない（そもそも見つからない）" do
      other_task = create(:task, user: create(:user))

      delete task_path(other_task)

      expect(response).to have_http_status(:not_found)
      expect(Task.exists?(other_task.id)).to be(true)
    end
  end
end
