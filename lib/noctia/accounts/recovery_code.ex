defmodule Noctia.Accounts.RecoveryCode do
  @moduledoc """
  Single-use password recovery codes.

  Codes are 128 random bits shown once as Base32 (`XXXX-XXXX-...`).
  Only the SHA-256 of the normalized code is stored; plain SHA-256 is enough
  because the code itself is unguessable (unlike a user-chosen password).
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_recovery_codes" do
    field :hashed_code, :binary
    belongs_to :user, Noctia.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a code formatted for display, e.g. `MZXW-6YTB-OI2E-K3DF-PJ5H-UZQT-NF`.
  """
  def generate do
    :crypto.strong_rand_bytes(16)
    |> Base.encode32(padding: false)
    |> String.graphemes()
    |> Enum.chunk_every(4)
    |> Enum.map_join("-", &Enum.join/1)
  end

  @doc """
  Hashes a code after normalizing it, so case, dashes and spaces don't matter.
  """
  def hash(code) when is_binary(code) do
    normalized = code |> String.upcase() |> String.replace(~r/[^A-Z2-7]/, "")
    :crypto.hash(:sha256, normalized)
  end
end
