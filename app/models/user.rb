class User < ApplicationRecord
  # Q19: 簡易形式チェック。ローカル部・@・ドメイン・.・TLD が揃っていることだけを見る。
  # "mize" / "mize@" / "@example.com" を弾き、"mize@example.com" を通す。
  # 実在確認は行わない（Q19）。
  EMAIL_ADDRESS_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  # パスワードの検証は RewardMe 2 側で持つ。
  # has_secure_password の標準検証はメッセージを message: で差し替えられず英語のままになるため、
  # validations: false で止めて、必要な検証をこのファイルへ明示する。
  # このオプションが止めるのは検証だけで、password= / authenticate / パスワードリセット用
  # トークンの生成は従来どおり有効。
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  # Task は必ず1人の User に属する（docs/product-specs/task.md 1章）。
  # User を削除したとき Task をどう扱うかは未確定のため、dependent は指定しない。
  has_many :tasks

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # エラーは full_messages ではなく属性ごとに表示するため、
  # message は単独で意味が通る日本語の文にしている。
  validates :email_address,
            presence: { message: "メールアドレスを入力してください" },
            format: { with: EMAIL_ADDRESS_FORMAT, allow_blank: true,
                      message: "メールアドレスの形式が正しくありません" },
            uniqueness: { message: "このメールアドレスは既に登録されています" }

  # Q18: 最低6文字。文字種の制約は設けない。
  # 未入力は password_must_be_present が受け持つため allow_blank にして二重表示を避ける。
  validates :password,
            length: { minimum: 6, allow_blank: true,
                      message: "パスワードは6文字以上で入力してください" },
            confirmation: { allow_nil: true, message: "パスワードが一致しません" }

  validate :password_must_be_present
  validate :password_must_fit_bcrypt_limit

  private
    # password ではなく password_digest の有無で見る。
    # こうすると、パスワードを送らない既存レコードの更新でも成立する。
    def password_must_be_present
      errors.add(:password, "パスワードを入力してください") if password_digest.blank?
    end

    # bcrypt が扱えるのは72バイトまで。超過分は黙って切り捨てられるため、明示的に弾く。
    def password_must_fit_bcrypt_limit
      limit = ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
      return if password.blank? || password.bytesize <= limit

      errors.add(:password, "パスワードは#{limit}バイト以内で入力してください")
    end
end
