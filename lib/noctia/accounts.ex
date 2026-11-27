defmodule Noctia.Accounts do
  @moduledoc """
  The Accounts context.

  Noctia has exactly one user: it is registered once, after which
  registration is closed for good.
  """

  import Ecto.Query, warn: false
  alias Noctia.Repo

  alias Noctia.Accounts.{RecoveryCode, User, UserToken}

  @recovery_code_count 10

  ## Registration

  @doc """
  Returns true while no user has been registered yet.
  """
  def registration_open? do
    not Repo.exists?(User)
  end

  @doc """
  Registers the single user and generates their recovery codes.

  Returns `{:ok, {user, codes}}`, where `codes` are the plain recovery codes
  to show once. Fails with a "registration is closed" error on `:username`
  once a user exists.
  """
  def register_user(attrs) do
    Repo.transact(fn ->
      with {:ok, user} <- %User{} |> User.registration_changeset(attrs) |> Repo.insert() do
        {:ok, {user, insert_recovery_codes!(user)}}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking registration changes.
  """
  def change_user_registration(user \\ %User{}, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Recovery codes

  @doc """
  Returns how many unused recovery codes the user has left.
  """
  def count_recovery_codes(%User{} = user) do
    Repo.aggregate(from(c in RecoveryCode, where: c.user_id == ^user.id), :count)
  end

  @doc """
  Replaces all recovery codes with a new set after checking `current_password`.

  Returns `{:ok, codes}` or `{:error, :invalid_password}`.
  """
  def regenerate_recovery_codes(%User{} = user, current_password) do
    if User.valid_password?(user, current_password) do
      Repo.transact(fn ->
        Repo.delete_all(from(c in RecoveryCode, where: c.user_id == ^user.id))
        {:ok, insert_recovery_codes!(user)}
      end)
    else
      {:error, :invalid_password}
    end
  end

  @doc """
  Resets the password using a recovery code. The code is consumed and every
  session is expired.

  The new password is validated before the code is checked, so a bad password
  never consumes (or confirms) a code.

  Returns `{:ok, {user, expired_tokens}}`, `{:error, :invalid_code}` (unknown
  username or code) or `{:error, changeset}`.
  """
  def reset_password_with_recovery_code(username, code, attrs)
      when is_binary(username) and is_binary(code) do
    Repo.transact(fn ->
      with %User{} = user <- Repo.get_by(User, username: username),
           %Ecto.Changeset{valid?: true} = changeset <- User.password_changeset(user, attrs),
           %RecoveryCode{} = recovery_code <-
             Repo.get_by(RecoveryCode, user_id: user.id, hashed_code: RecoveryCode.hash(code)),
           {:ok, user} <- Repo.update(changeset) do
        Repo.delete!(recovery_code)

        {_count, expired_tokens} =
          Repo.delete_all(from(t in UserToken, where: t.user_id == ^user.id, select: t))

        {:ok, {user, expired_tokens}}
      else
        nil -> {:error, :invalid_code}
        %Ecto.Changeset{} = changeset -> {:error, Map.put(changeset, :action, :update)}
        {:error, changeset} -> {:error, changeset}
      end
    end)
  end

  defp insert_recovery_codes!(user) do
    codes = for _ <- 1..@recovery_code_count, do: RecoveryCode.generate()
    now = DateTime.utc_now(:second)

    rows =
      for code <- codes do
        %{
          id: Ecto.UUID.generate(),
          user_id: user.id,
          hashed_code: RecoveryCode.hash(code),
          inserted_at: now
        }
      end

    Repo.insert_all(RecoveryCode, rows)
    codes
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
