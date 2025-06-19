defmodule Cue.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  alias Cue.Repo

  alias Cue.Groups.CueGroup
  alias Cue.Groups.UserCue
  alias Cue.Accounts.User

  @doc """
  Returns the list of cues.

  ## Examples

      iex> list_cues()
      [%CueGroup{}, ...]

  """
  def list_cues do
    Repo.all(CueGroup)
  end

  @doc """
  Gets a single cue.

  Raises `Ecto.NoResultsError` if the Cue does not exist.

  ## Examples

      iex> get_cue!(123)
      %CueGroup{}

      iex> get_cue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cue!(id), do: Repo.get!(CueGroup, id)

  @doc """
  Gets a single cue by its name.

  Returns nil if the Cue does not exist.

  ## Examples

      iex> get_cue_by_name("some name")
      %CueGroup{}

      iex> get_cue_by_name("nonexistent name")
      nil

  """
  def get_cue_by_name(name) when is_binary(name) do
    Repo.get_by(CueGroup, name: name)
  end

  @doc """
  Creates a cue.

  ## Examples

      iex> create_cue(%{field: value})
      {:ok, %CueGroup{}}

      iex> create_cue(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cue(attrs \\ %{}) do
    %CueGroup{}
    |> CueGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cue.

  ## Examples

      iex> update_cue(cue, %{field: new_value})
      {:ok, %CueGroup{}}

      iex> update_cue(cue, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cue(%CueGroup{} = cue, attrs) do
    cue
    |> CueGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cue.

  ## Examples

      iex> delete_cue(cue)
      {:ok, %CueGroup{}}

      iex> delete_cue(cue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cue(%CueGroup{} = cue) do
    Repo.delete(cue)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cue changes.

  ## Examples

      iex> change_cue(cue)
      %Ecto.Changeset{data: %CueGroup{}}

  """
  def change_cue(%CueGroup{} = cue, attrs \\ %{}) do
    CueGroup.changeset(cue, attrs)
  end

  @doc """
  Adds a user to a cue.

  ## Examples

      iex> add_user_to_cue(user, cue, %{role: "member"})
      {:ok, %UserCue{}}

      iex> add_user_to_cue(user, cue, %{role: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def add_user_to_cue(%User{} = user, %CueGroup{} = cue, attrs \\ %{}) do
    %UserCue{}
    |> UserCue.changeset(Map.merge(attrs, %{user_id: user.id, cue_id: cue.id}))
    |> Repo.insert()
  end

  @doc """
  Removes a user from a cue.

  ## Examples

      iex> remove_user_from_cue(user, cue)
      {:ok, %UserCue{}}

      iex> remove_user_from_cue(user, cue)
      {:error, %Ecto.Changeset{}}

  """
  def remove_user_from_cue(%User{} = user, %CueGroup{} = cue) do
    from(uc in UserCue, where: uc.user_id == ^user.id and uc.cue_id == ^cue.id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      user_cue -> Repo.delete(user_cue)
    end
  end

  @doc """
  Returns the list of cues for a user.

  ## Examples

      iex> list_user_cues(user)
      [%CueGroup{}, ...]

  """
  def list_user_cues(%User{} = user) do
    user = Repo.preload(user, :cues)
    user.cues
  end

  @doc """
  Returns the list of users in a cue.

  ## Examples

      iex> list_cue_users(cue)
      [%User{}, ...]

  """
  def list_cue_users(%CueGroup{} = cue) do
    cue = Repo.preload(cue, :users)
    cue.users
  end

  @doc """
  Checks if a user is a member of a cue.

  ## Examples

      iex> is_member?(user, cue)
      true

  """
  def is_member?(%User{} = user, %CueGroup{} = cue) do
    query = from uc in UserCue,
            where: uc.user_id == ^user.id and uc.cue_id == ^cue.id,
            select: count(uc.id)

    Repo.one(query) > 0
  end

  @doc """
  Gets the role of a user in a cue.

  ## Examples

      iex> get_user_role(user, cue)
      "admin"

      iex> get_user_role(user, cue)
      nil

  """
  def get_user_role(%User{} = user, %CueGroup{} = cue) do
    query = from uc in UserCue,
            where: uc.user_id == ^user.id and uc.cue_id == ^cue.id,
            select: uc.role

    Repo.one(query)
  end

  @doc """
  Updates the role of a user in a cue.

  ## Examples

      iex> update_user_role(user, cue, "admin")
      {:ok, %UserCue{}}

      iex> update_user_role(user, cue, "invalid")
      {:error, %Ecto.Changeset{}}

  """
  def update_user_role(%User{} = user, %CueGroup{} = cue, role) do
    from(uc in UserCue, where: uc.user_id == ^user.id and uc.cue_id == ^cue.id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      user_cue ->
        user_cue
        |> UserCue.changeset(%{role: role})
        |> Repo.update()
    end
  end
end
