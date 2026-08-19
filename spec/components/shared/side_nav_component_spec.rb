require "rails_helper"

RSpec.describe Shared::SideNavComponent, type: :component do
  # Tailwind のクラス名のような実装詳細ではなく、
  # 「利用者から見えるテキスト」と「支援技術に伝わる状態」を検証する。
  subject(:rendered) { render_inline(described_class.new(**options)) }

  let(:options) { {} }

  # 完成モック（rewardme_mock_3.html）の nav.menu と同じ並び。
  let(:nav_labels) do
    [ "ホーム", "タスク", "習慣", "お手紙", "お部屋ショップ", "アチーブメント", "設定" ]
  end

  describe "ブランド表示" do
    it "RewardMe のブランド名を表示する" do
      expect(rendered.text).to include("RewardMe")
    end

    it "キャッチコピーを表示する" do
      expect(rendered.text).to include("リボンちゃんと暮らすタスク管理アプリ")
    end

    it "ブランド名をページの見出しとして描画しない" do
      # SideNav は複数ページで共通表示されるため、h1 は各ページ固有の見出しに残す。
      expect(rendered.css("h1, h2, h3, h4, h5, h6")).to be_empty
    end
  end

  describe "ナビゲーション" do
    let(:nav) { rendered.at_css("nav") }

    it "完成モックどおりの項目を、その並び順で表示する" do
      items = nav.css("li")

      expect(items.size).to eq(nav_labels.size)
      nav_labels.each_with_index do |label, index|
        expect(items[index].text).to include(label)
      end
    end

    it "お手紙を表示する" do
      expect(nav.text).to include("お手紙")
    end

    it "お部屋ショップを表示する" do
      expect(nav.text).to include("お部屋ショップ")
    end

    it "ナビゲーション領域に名前を付ける" do
      expect(nav["aria-label"]).to eq("メインナビゲーション")
    end

    context "遷移先がまだ実装されていない項目" do
      it "リンクとして描画しない" do
        expect(nav.css("a")).to be_empty
      end

      it "無効かつ準備中であることを支援技術へ伝える" do
        expect(nav.css("[aria-disabled='true']").size).to eq(nav_labels.size)
        expect(nav.text).to include("（準備中）")
      end
    end

    context "現在地が渡されたとき" do
      let(:options) { { current: :home } }

      it "その項目だけを現在地として示す" do
        marked = nav.css("[aria-current='page']")

        expect(marked.size).to eq(1)
        expect(marked.first.text).to include("ホーム")
      end
    end

    context "現在地が渡されないとき" do
      it "どの項目も現在地として示さない" do
        expect(nav.css("[aria-current]")).to be_empty
      end
    end
  end
end
