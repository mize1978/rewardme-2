require "rails_helper"

RSpec.describe "Signup", type: :request do
  let(:valid_params) do
    { user: { email_address: "mize@example.com", password: "password", password_confirmation: "password" } }
  end

  describe "GET /registration/new" do
    it "未ログインでも登録画面を開ける" do
      get new_registration_path

      expect(response).to have_http_status(:ok)
    end

    it "ログイン済みなら Dashboard へ戻す" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get new_registration_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /registration（正常系）" do
    it "User を1件作成する" do
      expect { post registration_path, params: valid_params }.to change(User, :count).by(1)
    end

    it "同時にセッションを1件作成する（自動ログイン）" do
      expect { post registration_path, params: valid_params }.to change(Session, :count).by(1)
    end

    it "ログイン画面を経由せず Dashboard へ遷移する" do
      post registration_path, params: valid_params

      expect(response).to redirect_to(root_path)
      expect(response).not_to redirect_to(new_session_path)
    end

    it "登録直後から認証が必要なページを開ける" do
      post registration_path, params: valid_params

      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "メールアドレスを正規化して保存する" do
      post registration_path, params: { user: valid_params[:user].merge(email_address: "  Mize@Example.COM  ") }

      expect(User.last.email_address).to eq("mize@example.com")
    end
  end

  describe "POST /registration（失敗経路）" do
    # [ケース名, 上書きするパラメータ, 期待するメッセージ]
    [
      [ "F-01 メールアドレスが空",     { email_address: "" },                        "メールアドレスを入力してください" ],
      [ "F-02 mize",                    { email_address: "mize" },                    "メールアドレスの形式が正しくありません" ],
      [ "F-02 mize@",                   { email_address: "mize@" },                   "メールアドレスの形式が正しくありません" ],
      [ "F-02 @example.com",            { email_address: "@example.com" },            "メールアドレスの形式が正しくありません" ],
      [ "F-05 パスワードが空",          { password: "", password_confirmation: "" },  "パスワードを入力してください" ],
      [ "F-06 パスワードが5文字",       { password: "12345", password_confirmation: "12345" }, "パスワードは6文字以上で入力してください" ],
      [ "F-07 確認用が不一致",          { password_confirmation: "different" },       "パスワードが一致しません" ],
      [ "F-08 パスワードが73バイト",    { password: "a" * 73, password_confirmation: "a" * 73 }, "パスワードは72バイト以内で入力してください" ]
    ].each do |label, overrides, message|
      context label do
        let(:params) { { user: valid_params[:user].merge(overrides) } }

        it "User を作成しない" do
          expect { post registration_path, params: params }.not_to change(User, :count)
        end

        it "500 にならず、フォームを再描画してエラーを表示する" do
          post registration_path, params: params

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(message)
        end
      end
    end

    context "F-03 メールアドレスが既に登録されている" do
      before { create(:user, email_address: "mize@example.com") }

      it "User を作成しない" do
        expect { post registration_path, params: valid_params }.not_to change(User, :count)
      end

      it "500 にならず、重複であることを具体的に伝える" do
        post registration_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("このメールアドレスは既に登録されています")
      end
    end

    context "F-04 大文字・前後空白の違いだけの重複" do
      before { create(:user, email_address: "mize@example.com") }

      it "重複として扱い、F-03 と同じメッセージを出す" do
        post registration_path, params: { user: valid_params[:user].merge(email_address: "  Mize@Example.com  ") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("このメールアドレスは既に登録されています")
      end
    end

    context "F-10 uniqueness 検証をすり抜けて DB の UNIQUE INDEX に当たった" do
      before do
        # 検証と INSERT の間に別リクエストが同じアドレスを登録した状況を再現する。
        allow_any_instance_of(User).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
      end

      it "500 にせず、F-03 と同じ画面・同じメッセージで再描画する" do
        post registration_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("このメールアドレスは既に登録されています")
      end
    end

    describe "再描画時の入力保持" do
      it "メールアドレスは残し、パスワードは残さない" do
        post registration_path, params: { user: valid_params[:user].merge(password_confirmation: "different") }

        expect(response.body).to include("mize@example.com")
        expect(response.body).not_to include('value="password"')
      end
    end
  end
end
