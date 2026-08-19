require "rails_helper"

RSpec.describe User, type: :model do
  describe "メールアドレスの正規化" do
    it "前後の空白を落とし、小文字にして保存する" do
      user = create(:user, email_address: "  Mize@Example.COM  ")

      expect(user.email_address).to eq("mize@example.com")
    end
  end

  describe "メールアドレスの検証" do
    it "未入力なら無効になる" do
      user = build(:user, email_address: "")

      expect(user).to be_invalid
      expect(user.errors[:email_address]).to include("メールアドレスを入力してください")
    end

    # Q19 が明示している不正形式
    [ "mize", "mize@", "@example.com" ].each do |invalid|
      it "#{invalid.inspect} は形式エラーになる" do
        user = build(:user, email_address: invalid)

        expect(user).to be_invalid
        expect(user.errors[:email_address]).to include("メールアドレスの形式が正しくありません")
      end
    end

    it "mize@example.com は有効になる" do
      expect(build(:user, email_address: "mize@example.com")).to be_valid
    end

    it "既に登録されているメールアドレスは重複エラーになる" do
      create(:user, email_address: "mize@example.com")
      user = build(:user, email_address: "mize@example.com")

      expect(user).to be_invalid
      expect(user.errors[:email_address]).to include("このメールアドレスは既に登録されています")
    end

    it "大文字・前後空白の違いだけの場合も重複と判定する" do
      create(:user, email_address: "mize@example.com")
      user = build(:user, email_address: "  Mize@Example.com  ")

      expect(user).to be_invalid
      expect(user.errors[:email_address]).to include("このメールアドレスは既に登録されています")
    end
  end

  describe "パスワードの検証" do
    it "未入力なら無効になる" do
      user = build(:user, password: "", password_confirmation: "")

      expect(user).to be_invalid
      expect(user.errors[:password]).to include("パスワードを入力してください")
    end

    it "5文字なら無効になる" do
      user = build(:user, password: "12345", password_confirmation: "12345")

      expect(user).to be_invalid
      expect(user.errors[:password]).to include("パスワードは6文字以上で入力してください")
    end

    it "6文字なら有効になる" do
      expect(build(:user, password: "123456", password_confirmation: "123456")).to be_valid
    end

    it "記号や大文字を含まなくても有効になる" do
      expect(build(:user, password: "aaaaaa", password_confirmation: "aaaaaa")).to be_valid
    end

    it "確認用と一致しなければ無効になる" do
      user = build(:user, password: "password", password_confirmation: "different")

      expect(user).to be_invalid
      expect(user.errors[:password_confirmation]).to include("パスワードが一致しません")
    end

    it "72バイトを超えると無効になる" do
      user = build(:user, password: "a" * 73, password_confirmation: "a" * 73)

      expect(user).to be_invalid
      expect(user.errors[:password]).to include("パスワードは72バイト以内で入力してください")
    end
  end

  describe "パスワードの保管" do
    it "平文では保存しない" do
      user = create(:user, password: "password", password_confirmation: "password")

      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("password")
    end

    it "正しいパスワードでのみ認証できる" do
      user = create(:user, password: "password", password_confirmation: "password")

      expect(user.authenticate("password")).to eq(user)
      expect(user.authenticate("wrong")).to be(false)
    end
  end

  describe "セッションとの関連" do
    it "User を削除すると、その User のセッションも削除される" do
      user = create(:user)
      user.sessions.create!

      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end
end
