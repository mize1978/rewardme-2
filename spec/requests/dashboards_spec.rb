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
  end
end
