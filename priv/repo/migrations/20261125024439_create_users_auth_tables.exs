defmodule Noctia.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :citext, null: false
      add :hashed_password, :string, null: false

      timestamps(type: :utc_datetime)
    end

    # Noctia is single-user: a unique index over a constant expression allows
    # at most one row in the table, so a second registration fails even under races.
    create unique_index(:users, ["(true)"], name: :users_single_user_index)

    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:token])
  end
end
