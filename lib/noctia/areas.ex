defmodule Noctia.Areas do
  @moduledoc """
  The Areas context.
  """

  import Ecto.Query, warn: false
  alias Noctia.Repo

  alias Noctia.Areas.Area
  alias Noctia.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any area changes.

  The broadcasted messages match the pattern:

    * {:created, %Area{}}
    * {:updated, %Area{}}
    * {:deleted, %Area{}}

  """
  def subscribe_areas(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Noctia.PubSub, "user:#{key}:areas")
  end

  defp broadcast_area(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Noctia.PubSub, "user:#{key}:areas", message)
  end

  @doc """
  Returns the list of areas.

  ## Examples

      iex> list_areas(scope)
      [%Area{}, ...]

  """
  def list_areas(%Scope{} = scope) do
    Repo.all_by(Area, user_id: scope.user.id)
  end

  @doc """
  Gets a single area.

  Raises `Ecto.NoResultsError` if the Area does not exist.

  ## Examples

      iex> get_area!(scope, 123)
      %Area{}

      iex> get_area!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_area!(%Scope{} = scope, id) do
    Repo.get_by!(Area, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a area.

  ## Examples

      iex> create_area(scope, %{field: value})
      {:ok, %Area{}}

      iex> create_area(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_area(%Scope{} = scope, attrs) do
    with {:ok, area = %Area{}} <-
           %Area{}
           |> Area.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_area(scope, {:created, area})
      {:ok, area}
    end
  end

  @doc """
  Updates a area.

  ## Examples

      iex> update_area(scope, area, %{field: new_value})
      {:ok, %Area{}}

      iex> update_area(scope, area, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_area(%Scope{} = scope, %Area{} = area, attrs) do
    true = area.user_id == scope.user.id

    with {:ok, area = %Area{}} <-
           area
           |> Area.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_area(scope, {:updated, area})
      {:ok, area}
    end
  end

  @doc """
  Deletes a area.

  ## Examples

      iex> delete_area(scope, area)
      {:ok, %Area{}}

      iex> delete_area(scope, area)
      {:error, %Ecto.Changeset{}}

  """
  def delete_area(%Scope{} = scope, %Area{} = area) do
    true = area.user_id == scope.user.id

    with {:ok, area = %Area{}} <-
           Repo.delete(area) do
      broadcast_area(scope, {:deleted, area})
      {:ok, area}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking area changes.

  ## Examples

      iex> change_area(scope, area)
      %Ecto.Changeset{data: %Area{}}

  """
  def change_area(%Scope{} = scope, %Area{} = area, attrs \\ %{}) do
    true = area.user_id == scope.user.id

    Area.changeset(area, attrs, scope)
  end
end
