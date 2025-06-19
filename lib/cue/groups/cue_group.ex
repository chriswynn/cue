defmodule Cue.Groups.CueGroup do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

    schema "cues" do
    field :name, :string
    field :description, :string
    belongs_to :creator, Cue.Accounts.User

    many_to_many :users, Cue.Accounts.User,
                 join_through: Cue.Groups.UserCue,
                 join_keys: [cue_id: :id, user_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc """
  A cue changeset for creation.
  """
  def changeset(cue, attrs) do
    cue
    |> cast(attrs, [:name, :description, :creator_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, max: 1000)
    |> unique_constraint(:name)
  end
end
