defmodule Noctia.Accounts do
  @moduledoc """
  The Accounts context.

  Noctia has exactly one user: it is registered once, after which
  registration is closed for good.
  """

  import Ecto.Query, warn: false
  alias Noctia.Repo

  alias Noctia.Accounts.{User, UserToken}

  ## Registration

  @doc """
  Returns true while no user has been registered yet.
  """
  def registration_open? do
    not Repo.exists?(User)
  end

  @doc """
  Registers the single user.

  Fails with a "registration is closed" error on `:username` once a user exists.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking registration changes.
  """
  def change_user_registration(user \\ %User{}, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Authentication

  @doc """
  Gets the user by username and password, or nil.
  """
  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if User.valid_password?(user, password), do: user
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Noctia.Accounts.User.password_changeset/3` for a list of supported options.
  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password after checking `current_password`.

  Every session token except `keep_token` (the caller's own session) is
  deleted. Returns `{:ok, {user, expired_tokens}}` or `{:error, changeset}`.
  """
  def update_user_password(%User{} = user, current_password, attrs, keep_token) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(current_password)

    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        {_count, expired_tokens} =
          Repo.delete_all(
            from(t in UserToken,
              where: t.user_id == ^user.id and t.token != ^keep_token,
              select: t
            )
          )

        {:ok, {user, expired_tokens}}
      end
    end)
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets `{user, token_inserted_at}` for a valid session token, or nil.
  """
  def get_user_by_session_token(token) do
    token
    |> UserToken.verify_session_token_query()
    |> Repo.one()
  end

  @doc """
  Deletes the given session token.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token]))
    :ok
  end
end
