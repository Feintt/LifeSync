defmodule Noctia.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias Noctia.Accounts.UserToken

  @rand_size 32
  @session_validity_in_days 14

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_tokens" do
    field :token, :binary
    belongs_to :user, Noctia.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a session token, stored in the signed session/cookie.

  Tokens are persisted so sessions can be expired individually
  (log out, password change) instead of living as long as the cookie.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, user_id: user.id}}
  end

  @doc """
  Returns a query for `{user, token_inserted_at}` if the token exists and
  has not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    from t in UserToken,
      join: user in assoc(t, :user),
      where: t.token == ^token and t.inserted_at > ago(@session_validity_in_days, "day"),
      select: {user, t.inserted_at}
  end
end
