FactoryBot.define do
  factory :user do
    # email_address には UNIQUE INDEX があるため、複数作る spec でも衝突しないよう連番にする。
    sequence(:email_address) { |n| "user#{n}@example.com" }
    # Q18 の最低6文字を満たす値にする。
    password { "password" }
  end
end
