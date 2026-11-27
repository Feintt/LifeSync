defmodule Noctia.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Noctia.Accounts` context.

  Noctia allows a single user, so `user_fixture/1` can only be
  called once per test.
  """

  import Ecto.Query

  alias Noctia.Accounts
  alias Noctia.Accounts.Scope

  def valid_username, do: "noctia_admin"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: valid_username(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {user, _codes} = user_with_recovery_codes_fixture(attrs)
    user
  end

  def user_with_recovery_codes_fixture(attrs \\ %{}) do
    {:ok, {user, codes}} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    {user, codes}
  end

  def user_scope_fixture do
    Scope.for_user(user_fixture())
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Noctia.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt]
    )
  end
end
