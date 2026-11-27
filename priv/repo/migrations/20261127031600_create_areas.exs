defmodule Noctia.Repo.Migrations.CreateAreas do
  use Ecto.Migration

  def change do
    create table(:areas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :color, :string, null: false, default: "#6366f1"
      add :icon, :string, null: true
      add :archived_at, :utc_datetime
      add :position, :integer, null: false, default: 0
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:areas, [:user_id, :position])
  end
end
