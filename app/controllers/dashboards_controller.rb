# RewardMe 2 の入口となる Dashboard。完成モックの4カラム構成をここへ組み上げていく。
# 現時点では SideNav だけを配置しており、各カードは後続の施工で足す。
# MyRoom は独立画面ではなくこの Dashboard 内の領域として扱う（docs/design-decisions.md DD-001）。
class DashboardsController < ApplicationController
  def show
    # 表示データは Dashboard が定義する（DD-006）。
    @dashboard = Dashboard.new(user: Current.user)
  end
end
