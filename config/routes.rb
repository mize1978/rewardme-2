Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ViewComponent を実ブラウザで確認するためのデザイン確認ページ。
  # 本番画面が組み上がるまでの一時的な入口で、機能そのものは持たない。
  # 開発用の入口が本番へ残らないよう、development でのみルーティングする。
  if Rails.env.development?
    get "design/side_nav" => "design_previews#side_nav", as: :design_side_nav
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
