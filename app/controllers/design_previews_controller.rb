# 実装したViewComponentを実ブラウザで確認するための、開発用の表示専用コントローラ。
# ダッシュボード等の本番画面が組み上がるまでの間、コンポーネント単体を素の状態で見るために使う。
class DesignPreviewsController < ApplicationController
  def side_nav
  end
end
