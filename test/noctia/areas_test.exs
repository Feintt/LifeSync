defmodule Noctia.AreasTest do
  use Noctia.DataCase

  alias Noctia.Areas

  describe "areas" do
    alias Noctia.Areas.Area

    import Noctia.AccountsFixtures, only: [user_scope_fixture: 0]
    import Noctia.AreasFixtures

    @invalid_attrs %{name: nil, position: nil, color: nil, icon: nil, archived_at: nil}

    test "list_areas/1 returns all scoped areas" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      area = area_fixture(scope)
      other_area = area_fixture(other_scope)
      assert Areas.list_areas(scope) == [area]
      assert Areas.list_areas(other_scope) == [other_area]
    end

    test "get_area!/2 returns the area with given id" do
      scope = user_scope_fixture()
      area = area_fixture(scope)
      other_scope = user_scope_fixture()
      assert Areas.get_area!(scope, area.id) == area
      assert_raise Ecto.NoResultsError, fn -> Areas.get_area!(other_scope, area.id) end
    end

    test "create_area/2 with valid data creates a area" do
      valid_attrs = %{name: "some name", position: 42, color: "some color", icon: "some icon", archived_at: ~D[2026-11-26]}
      scope = user_scope_fixture()

      assert {:ok, %Area{} = area} = Areas.create_area(scope, valid_attrs)
      assert area.name == "some name"
      assert area.position == 42
      assert area.color == "some color"
      assert area.icon == "some icon"
      assert area.archived_at == ~D[2026-11-26]
      assert area.user_id == scope.user.id
    end

    test "create_area/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Areas.create_area(scope, @invalid_attrs)
    end

    test "update_area/3 with valid data updates the area" do
      scope = user_scope_fixture()
      area = area_fixture(scope)
      update_attrs = %{name: "some updated name", position: 43, color: "some updated color", icon: "some updated icon", archived_at: ~D[2026-11-27]}

      assert {:ok, %Area{} = area} = Areas.update_area(scope, area, update_attrs)
      assert area.name == "some updated name"
      assert area.position == 43
      assert area.color == "some updated color"
      assert area.icon == "some updated icon"
      assert area.archived_at == ~D[2026-11-27]
    end

    test "update_area/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      area = area_fixture(scope)

      assert_raise MatchError, fn ->
        Areas.update_area(other_scope, area, %{})
      end
    end

    test "update_area/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      area = area_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Areas.update_area(scope, area, @invalid_attrs)
      assert area == Areas.get_area!(scope, area.id)
    end

    test "delete_area/2 deletes the area" do
      scope = user_scope_fixture()
      area = area_fixture(scope)
      assert {:ok, %Area{}} = Areas.delete_area(scope, area)
      assert_raise Ecto.NoResultsError, fn -> Areas.get_area!(scope, area.id) end
    end

    test "delete_area/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      area = area_fixture(scope)
      assert_raise MatchError, fn -> Areas.delete_area(other_scope, area) end
    end

    test "change_area/2 returns a area changeset" do
      scope = user_scope_fixture()
      area = area_fixture(scope)
      assert %Ecto.Changeset{} = Areas.change_area(scope, area)
    end
  end
end
