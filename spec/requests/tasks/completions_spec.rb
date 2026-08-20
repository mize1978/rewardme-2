require "rails_helper"

RSpec.describe "Task completions", type: :request do
  let(:user) { create(:user) }

  def sign_in(as:)
    post session_path, params: { email_address: as.email_address, password: "password" }
  end

  before { sign_in(as: user) }

  describe "POST /tasks/:task_id/completion" do
    it "完了時刻が記録される（正本6章）" do
      task = create(:task, user: user)

      travel_to Time.zone.local(2026, 8, 20, 10, 0) do
        post task_completion_path(task)

        expect(task.reload.completed_at).to eq(Time.zone.local(2026, 8, 20, 10, 0))
      end

      expect(response).to redirect_to(root_path)
    end

    it "完了済みへ再度送っても完了時刻を書き換えない（DD-005）" do
      completed_at = Time.zone.local(2026, 8, 20, 10, 0)
      task = create(:task, user: user, completed_at: completed_at)

      travel_to Time.zone.local(2026, 8, 20, 23, 0) do
        post task_completion_path(task)
      end

      expect(task.reload.completed_at).to eq(completed_at)
    end

    it "他人の Task は完了できない（そもそも見つからない）" do
      other_task = create(:task, user: create(:user))

      post task_completion_path(other_task)

      expect(response).to have_http_status(:not_found)
      expect(other_task.reload).to be_incomplete
    end
  end

  describe "DELETE /tasks/:task_id/completion" do
    it "完了を取り消して未完了へ戻せる（正本6章）" do
      task = create(:task, user: user, completed_at: Time.current)

      delete task_completion_path(task)

      expect(task.reload.completed_at).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "未完了へ送っても何も起きない（DD-005）" do
      task = create(:task, user: user)

      expect {
        delete task_completion_path(task)
      }.not_to change { task.reload.updated_at }

      expect(task.reload).to be_incomplete
    end

    it "他人の Task の完了は取り消せない（そもそも見つからない）" do
      completed_at = Time.zone.local(2026, 8, 20, 10, 0)
      other_task = create(:task, user: create(:user), completed_at: completed_at)

      delete task_completion_path(other_task)

      expect(response).to have_http_status(:not_found)
      expect(other_task.reload.completed_at).to eq(completed_at)
    end
  end

  it "未ログインでは完了できず、ログイン画面へ誘導される" do
    delete session_path
    task = create(:task, user: user)

    post task_completion_path(task)

    expect(task.reload).to be_incomplete
    expect(response).to redirect_to(new_session_path)
  end
end
