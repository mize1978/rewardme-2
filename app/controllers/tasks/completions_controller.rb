# Task の完了・完了取消。完了は「状態を作る／取り消す」操作として単数リソースで表す（DD-005）。
class Tasks::CompletionsController < ApplicationController
  before_action :set_task

  def create
    # すでに完了している Task の completed_at は書き換えない。
    # 書き換えると「完了操作をした当日だけ残る」判定の基準日がずれる（正本6章、DD-005）。
    @task.update!(completed_at: Time.current) if @task.incomplete?

    redirect_to root_path
  end

  def destroy
    @task.update!(completed_at: nil) if @task.completed?

    redirect_to root_path, status: :see_other
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:task_id])
    end
end
