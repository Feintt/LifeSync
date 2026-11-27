defmodule Noctia.Areas.Area do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "areas" do
    field :name, :string
    field :color, :string
    field :icon, :string
    field :archived_at, :utc_datetime
    field :position, :integer
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(area, attrs, user_scope) do
    area
    |> cast(attrs, [:name, :color, :icon])
    |> validate_required([:name])
    |> validate_length(:name, max: 60)
    |> validate_format(:color, ~r"^#[0-9a-fA-F]{6}$")
    |> put_change(:user_id, user_scope.user.id)
  end
end
