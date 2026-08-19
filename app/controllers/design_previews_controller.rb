# 実装したViewComponentを実ブラウザで確認するための、開発用の表示専用コントローラ。
# ダッシュボード等の本番画面が組み上がるまでの間、コンポーネント単体を素の状態で見るために使う。
class DesignPreviewsController < ApplicationController
  # コンポーネントの見た目を確認するだけのページで、ユーザーのデータを一切扱わない。
  # development でしかルーティングされないため、ログインを要求しない。
  allow_unauthenticated_access

  def side_nav
  end
end
