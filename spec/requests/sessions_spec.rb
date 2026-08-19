require "rails_helper"

RSpec.describe "ログイン", type: :request do
  let!(:user) { create(:user, email_address: "mize@example.com", password: "password") }

  describe "GET /session/new" do
    it "未ログインでもログイン画面を開ける" do
      get new_session_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "正しいメールアドレスとパスワードでログインできる" do
      expect {
        post session_path, params: { email_address: "mize@example.com", password: "password" }
      }.to change(Session, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "パスワードが誤っているとログインできない" do
      expect {
        post session_path, params: { email_address: "mize@example.com", password: "wrong" }
      }.not_to change(Session, :count)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("メールアドレスまたはパスワードが正しくありません。")
    end

    it "登録されていないメールアドレスではログインできない" do
      expect {
        post session_path, params: { email_address: "unknown@example.com", password: "password" }
      }.not_to change(Session, :count)

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "DELETE /session" do
    it "ログアウトするとセッションが破棄される" do
      post session_path, params: { email_address: "mize@example.com", password: "password" }

      expect { delete session_path }.to change(Session, :count).by(-1)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
