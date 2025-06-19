defmodule Cue.Groups.UserCue do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "user_cues" do
    field :role, :string, default: "member"
    belongs_to :user, Cue.Accounts.User
    belongs_to :cue, Cue.Groups.CueGroup

    timestamps(type: :utc_datetime)
  end

  @valid_roles ~w(admin member)

  @doc """
  A user_cue changeset for creation.
  """
  def changeset(user_cue, attrs) do
    user_cue
    |> cast(attrs, [:user_id, :cue_id, :role])
    |> validate_required([:user_id, :cue_id, :role])
    |> validate_inclusion(:role, @valid_roles)
    |> unique_constraint([:user_id, :cue_id])
  end
end
