import { Controller } from "@hotwired/stimulus"

// 今日のタスクカードの作成フォームを開閉する。
// 担当するのは開閉だけで、Task の作成はフォームがサーバへ送る（DD-008）。
export default class extends Controller {
  static targets = ["panel", "opener"]
  static values = { open: Boolean }

  connect() {
    this.openValueChanged()
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    this.panelTarget.hidden = !this.openValue
    this.openerTarget.hidden = this.openValue
  }
}
