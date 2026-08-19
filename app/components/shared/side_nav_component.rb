module Shared
  # RewardMe のブランド情報と主要画面へのナビゲーションを表示する。
  #
  # 完成モック（rewardme_mock_3.html）の .nav-col.card を正本とし、
  # 「ブランド領域」と「ナビゲーション」の2ブロックで構成する。
  #
  # 表示責務のみを持つ。DBアクセス・EXP計算・タスクロジック・成長判定は持たない。
  # 外から渡すのは「現在どの画面にいるか」だけで、表示内容自体は静的に定義する。
  class SideNavComponent < ViewComponent::Base
    # path は「その画面のルーティングが存在するか」を表す。
    # RewardMe 2 ではまだどの画面も実装していないため、現時点ではすべて nil。
    # nil の項目はリンクにせず、aria-disabled な要素として描画する（壊れた href を作らない）。
    NavItem = Data.define(:key, :label, :icon, :path) do
      def navigable?
        !path.nil?
      end
    end

    # 並び順・ラベル・アイコンはすべて完成モックの nav.menu に合わせている。
    NAV_ITEMS = [
      NavItem.new(key: :home,         label: "ホーム",         icon: "🏠", path: nil),
      NavItem.new(key: :tasks,        label: "タスク",         icon: "🗒️", path: nil),
      NavItem.new(key: :habits,       label: "習慣",           icon: "🕐", path: nil),
      NavItem.new(key: :letters,      label: "お手紙",         icon: "💌", path: nil),
      NavItem.new(key: :room_shop,    label: "お部屋ショップ", icon: "🛍️", path: nil),
      NavItem.new(key: :achievements, label: "アチーブメント", icon: "🏆", path: nil),
      NavItem.new(key: :settings,     label: "設定",           icon: "⚙️", path: nil)
    ].freeze

    # @param current [Symbol, String, nil] 現在地を表す NAV_ITEMS の key。nil なら現在地を示さない。
    def initialize(current: nil)
      @current = current&.to_sym
    end

    attr_reader :current

    def nav_items
      NAV_ITEMS
    end

    def current?(item)
      !current.nil? && item.key == current
    end
  end
end
