# 新規登録（Signup）。誰でも登録できる（Q16）。
# 登録に成功したらそのままログイン状態にして Dashboard へ送る（Q17）。
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_authenticated_user

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    # uniqueness validation は SELECT してから INSERT するため、同時登録では
    # 両方が validation を通過し、後発が DB の UNIQUE INDEX に当たることがある。
    # Q20 により、この経路を 500 のまま放置せず通常の重複エラーと同じ扱いにする。
    @user.errors.add(:email_address, :taken, message: "このメールアドレスは既に登録されています")
    render :new, status: :unprocessable_content
  end

  private
    def registration_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end

    def redirect_authenticated_user
      redirect_to root_path if authenticated?
    end
end
