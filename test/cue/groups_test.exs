defmodule Cue.GroupsTest do
  use Cue.DataCase

  alias Cue.Groups
  alias Cue.Groups.CueGroup
  alias Cue.Accounts

  describe "cues" do
    import Cue.AccountsFixtures

    @valid_attrs %{name: "some name", description: "some description"}
    @update_attrs %{name: "updated name", description: "updated description"}
    @invalid_attrs %{name: nil, description: nil}

    setup do
      {:ok, user: user_fixture()}
    end

    test "list_cues/0 returns all cues", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert Groups.list_cues() == [cue]
    end

    test "get_cue!/1 returns the cue with given id", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert Groups.get_cue!(cue.id) == cue
    end

    test "get_cue_by_name/1 returns the cue with given name", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert Groups.get_cue_by_name(cue.name) == cue
    end

    test "create_cue/1 with valid data creates a cue", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      assert {:ok, %CueGroup{} = cue} = Groups.create_cue(attrs)
      assert cue.name == "some name"
      assert cue.description == "some description"
      assert cue.creator_id == user.id
    end

    test "create_cue/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_cue(@invalid_attrs)
    end

    test "update_cue/2 with valid data updates the cue", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert {:ok, %CueGroup{} = cue} = Groups.update_cue(cue, @update_attrs)
      assert cue.name == "updated name"
      assert cue.description == "updated description"
    end

    test "update_cue/2 with invalid data returns error changeset", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert {:error, %Ecto.Changeset{}} = Groups.update_cue(cue, @invalid_attrs)
      assert cue == Groups.get_cue!(cue.id)
    end

    test "delete_cue/1 deletes the cue", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert {:ok, %CueGroup{}} = Groups.delete_cue(cue)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_cue!(cue.id) end
    end

    test "change_cue/1 returns a cue changeset", %{user: user} do
      attrs = Map.put(@valid_attrs, :creator_id, user.id)
      {:ok, cue} = Groups.create_cue(attrs)
      assert %Ecto.Changeset{} = Groups.change_cue(cue)
    end
  end

  describe "user_cues" do
    import Cue.AccountsFixtures

    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, cue} = Groups.create_cue(%{name: "Test Cue", creator_id: user1.id})

      {:ok, user1: user1, user2: user2, cue: cue}
    end

    test "add_user_to_cue/3 adds a user to a cue", %{user1: user1, cue: cue} do
      assert {:ok, user_cue} = Groups.add_user_to_cue(user1, cue)
      assert user_cue.user_id == user1.id
      assert user_cue.cue_id == cue.id
      assert user_cue.role == "member"
    end

    test "add_user_to_cue/3 with custom role", %{user1: user1, cue: cue} do
      assert {:ok, user_cue} = Groups.add_user_to_cue(user1, cue, %{role: "admin"})
      assert user_cue.role == "admin"
    end

    test "add_user_to_cue/3 with invalid role", %{user1: user1, cue: cue} do
      assert {:error, changeset} = Groups.add_user_to_cue(user1, cue, %{role: "invalid"})
      assert "is invalid" in errors_on(changeset).role
    end

    test "remove_user_from_cue/2 removes a user from a cue", %{user1: user1, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue)
      assert {:ok, _} = Groups.remove_user_from_cue(user1, cue)
      assert Groups.is_member?(user1, cue) == false
    end

    test "list_user_cues/1 returns all cues for a user", %{user1: user1, user2: user2, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue)

      {:ok, cue2} = Groups.create_cue(%{name: "Another Cue", creator_id: user2.id})
      {:ok, _} = Groups.add_user_to_cue(user1, cue2)

      user_cues = Groups.list_user_cues(user1)
      assert length(user_cues) == 2
      assert Enum.any?(user_cues, fn c -> c.id == cue.id end)
      assert Enum.any?(user_cues, fn c -> c.id == cue2.id end)
    end

    test "list_cue_users/1 returns all users in a cue", %{user1: user1, user2: user2, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue)
      {:ok, _} = Groups.add_user_to_cue(user2, cue)

      cue_users = Groups.list_cue_users(cue)
      assert length(cue_users) == 2
      assert Enum.any?(cue_users, fn u -> u.id == user1.id end)
      assert Enum.any?(cue_users, fn u -> u.id == user2.id end)
    end

    test "is_member?/2 checks if a user is a member of a cue", %{user1: user1, user2: user2, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue)

      assert Groups.is_member?(user1, cue) == true
      assert Groups.is_member?(user2, cue) == false
    end

    test "get_user_role/2 returns the role of a user in a cue", %{user1: user1, user2: user2, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue, %{role: "admin"})

      assert Groups.get_user_role(user1, cue) == "admin"
      assert Groups.get_user_role(user2, cue) == nil
    end

    test "update_user_role/3 updates the role of a user in a cue", %{user1: user1, cue: cue} do
      {:ok, _} = Groups.add_user_to_cue(user1, cue)
      assert Groups.get_user_role(user1, cue) == "member"

      {:ok, user_cue} = Groups.update_user_role(user1, cue, "admin")
      assert user_cue.role == "admin"
      assert Groups.get_user_role(user1, cue) == "admin"
    end
  end
end
