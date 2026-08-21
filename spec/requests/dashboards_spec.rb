require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "未ログインではログイン画面へ誘導される" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "ログイン済みなら表示できる" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "今日のタスクが描画される" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
      create(:task, user: user, title: "ゴミ出し", due_on: Date.current)
      create(:task, user: user, title: "来週の下見", due_on: Date.current + 7)

      get root_path

      expect(response.body).to include("ゴミ出し")
      expect(response.body).not_to include("来週の下見")
    end

    it "同じタスクを二重に描画しない" do
      # 暫定の <ul> を撤去し忘れると、Component と両方が描いて二重になる（DD-008）。
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
      create(:task, user: user, title: "ゴミ出し", due_on: Date.current)

      get root_path

      # aria-label にもタイトルが入るため、属性ではなく本文テキストだけを数える。
      expect(Nokogiri::HTML(response.body).text.scan("ゴミ出し").size).to eq(1)
    end

    it "完了済みのタスクは描画しない（配置が未確定・DD-008）" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
      create(:task, user: user, title: "完了したやつ", completed_at: Time.current)

      get root_path

      expect(response.body).not_to include("完了したやつ")
    end

    it "他人のタスクは描画されない" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
      create(:task, user: create(:user), title: "他人のタスク", due_on: Date.current)

      get root_path

      expect(response.body).not_to include("他人のタスク")
    end
  end
end
