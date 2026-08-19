FactoryBot.define do
  factory :task do
    user
    sequence(:title) { |n| "タスク#{n}" }
    # due_on / completed_at は既定で nil。必要な spec 側で明示する。
  end
end
