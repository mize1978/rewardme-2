# Task の作成と削除。表示は Dashboard が受け持つため、この Controller は画面を持たない。
# 経路の形とその理由は docs/design-decisions.md の DD-005 を参照。
class TasksController < ApplicationController
  def create
    # 他人の Task を作れないよう、必ず Current.user から生やす。
    @task = Current.user.tasks.build(task_params)

    if @task.save
      redirect_to root_path
    else
      # 失敗経路をリダイレクトで握り潰さない（DD-005）。
      # エラーの描画は作成フォームを Dashboard へ載せる施工で足す。
      render "dashboards/show", status: :unprocessable_content
    end
  end

  def destroy
    # 未完了・完了済みのどちらも削除できる（正本7章）。
    # 他人の Task は Current.user 経由のため、そもそも見つからない。
    Current.user.tasks.find(params[:id]).destroy!

    redirect_to root_path, status: :see_other
  end

  private
    # 報酬額や完了状態はユーザーからの入力で決まらないため、受け取るのは title と due_on だけ。
    def task_params
      params.expect(task: [ :title, :due_on ])
    end
end
