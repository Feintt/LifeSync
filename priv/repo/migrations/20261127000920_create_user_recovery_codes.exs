defmodule Noctia.Repo.Migrations.CreateUserRecoveryCodes do
  use Ecto.Migration

  def change do
    create table(:user_recovery_codes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :hashed_code, :binary, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:user_recovery_codes, [:user_id, :hashed_code])
  end
end
