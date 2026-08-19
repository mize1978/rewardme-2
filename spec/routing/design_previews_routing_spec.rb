require "rails_helper"

RSpec.describe "デザイン確認ページのルーティング", type: :routing do
  # config/routes.rb では `Rails.env.development?` でのみ描画している。
  # RSpec は test 環境で動くため、この spec が通ること自体が
  # 「development 以外の環境ではルートが存在しない」ことの証明になる。
  # （環境の stub もルート再読み込みも要らない）
  it "development 以外の環境ではデザイン確認ページへルーティングしない" do
    expect(get: "/design/side_nav").not_to be_routable
  end
end
