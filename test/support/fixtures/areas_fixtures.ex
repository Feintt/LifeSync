defmodule Noctia.AreasFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Noctia.Areas` context.
  """

  @doc """
  Generate a area.
  """
  def area_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        archived_at: ~D[2026-11-26],
        color: "some color",
        icon: "some icon",
        name: "some name",
        position: 42
      })

    {:ok, area} = Noctia.Areas.create_area(scope, attrs)
    area
  end
end
